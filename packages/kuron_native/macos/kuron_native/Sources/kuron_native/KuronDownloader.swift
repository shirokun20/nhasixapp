import FlutterMacOS
import Foundation

/// Foreground download manager for macOS (URLSession based).
///
/// Mirrors the Android WorkManager worker contract the Dart side expects:
/// - files land in `<destinationPath>/images/page_NNN.ext` (same layout the
///   offline reader and resume logic scan for)
/// - progress flows through the `kuron_native/download_progress` event
///   channel as {contentId, status, downloadedPages, totalPages,
///   downloadSpeed}, with status COMPLETED/FAILED, anything else = progress
/// - pause suspends tasks (resume = start again, existing pages skipped);
///   cancel drops the job
/// - every entry point settles exactly once; unknown contentIds resolve
///   gracefully instead of throwing
final class KuronDownloadCenter: NSObject {
  static let shared = KuronDownloadCenter()

  private struct Page: Sendable {
    let number: Int
    let url: String
    let headers: [String: String]
  }

  private final class Job: NSObject, URLSessionDownloadDelegate {
    let contentId: String
    let pages: [Page]
    let imagesDir: URL
    let timeout: TimeInterval
    var tasks: [URLSessionDownloadTask] = []
    var session: URLSession!
    var done = Set<Int>()
    var bytesSinceEmit: Int64 = 0
    var startedAt = Date()
    var lastEmit = Date()
    var finished = false
    var failed = false
    weak var center: KuronDownloadCenter?

    init(contentId: String, pages: [Page], imagesDir: URL, timeout: TimeInterval, center: KuronDownloadCenter) {
      self.contentId = contentId
      self.pages = pages
      self.imagesDir = imagesDir
      self.timeout = timeout
      self.center = center
    }

    func start(maxParallel: Int) {
      let config = URLSessionConfiguration.default
      config.timeoutIntervalForRequest = timeout
      config.timeoutIntervalForResource = max(timeout * 10, 600)
      config.httpMaximumConnectionsPerHost = max(1, min(maxParallel, 8))
      session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
      for page in pages {
        guard let url = URL(string: page.url) else { continue }
        if localPath(for: page) != nil { done.insert(page.number); continue }
        var req = URLRequest(url: url)
        req.timeoutInterval = timeout
        for (k, v) in page.headers { req.setValue(v, forHTTPHeaderField: k) }
        let task = session.downloadTask(with: req)
        task.taskDescription = "\(page.number)"
        tasks.append(task)
      }
      startedAt = Date()
      lastEmit = startedAt
      tasks.forEach { $0.resume() }
      emit(status: "DOWNLOADING", force: true)
      if tasks.isEmpty { finishSuccessfullyIfComplete() }
    }

    private func fileName(pageNumber: Int, url: String) -> String {
      let lower = (URL(string: url)?.path ?? url).lowercased()
      let ext: String
      if lower.hasSuffix(".avif") { ext = ".avif" }
      else if lower.hasSuffix(".webp") { ext = ".webp" }
      else if lower.hasSuffix(".png") { ext = ".png" }
      else if lower.hasSuffix(".gif") { ext = ".gif" }
      else if lower.hasSuffix(".bmp") { ext = ".bmp" }
      else if lower.hasSuffix(".jpeg") { ext = ".jpeg" }
      else { ext = ".jpg" }
      return String(format: "page_%03d%@", pageNumber, ext)
    }

    private func localPath(for page: Page) -> URL? {
      let f = imagesDir.appendingPathComponent(fileName(pageNumber: page.number, url: page.url))
      if let attrs = try? FileManager.default.attributesOfItem(atPath: f.path),
         let size = attrs[.size] as? NSNumber, size.intValue > 0 { return f }
      return nil
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
      bytesSinceEmit += bytesWritten
      let now = Date()
      if now.timeIntervalSince(lastEmit) >= 0.5 { emit(status: "DOWNLOADING") }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
      guard let num = Int(downloadTask.taskDescription ?? "") else { return }
      guard let page = pages.first(where: { $0.number == num }) else { return }
      do {
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        let dest = imagesDir.appendingPathComponent(fileName(pageNumber: num, url: page.url))
        if FileManager.default.fileExists(atPath: dest.path) {
          try? FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: location, to: dest)
        done.insert(num)
      } catch {
        fail()
        return
      }
      emit(status: "DOWNLOADING")
      finishSuccessfullyIfComplete()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      if error != nil {
        // Cancelled tasks report NSURLErrorCancelled — not a failure.
        let code = (error as NSError?)?.code
        if code == NSURLErrorCancelled { return }
        fail()
      }
    }

    private func speed() -> Double {
      let dt = Date().timeIntervalSince(lastEmit)
      guard dt > 0 else { return 0 }
      return Double(bytesSinceEmit) / dt
    }

    private func emit(status: String, force: Bool = false) {
      lastEmit = Date()
      let payload: [String: Any] = [
        "contentId": contentId,
        "status": status,
        "downloadedPages": done.count,
        "totalPages": pages.count,
        "downloadSpeed": speed(),
      ]
      bytesSinceEmit = 0
      KuronDownloadEvents.send(payload)
      _ = force
    }

    private func finishSuccessfullyIfComplete() {
      guard !finished, done.count >= pages.count, !pages.isEmpty else { return }
      finished = true
      emit(status: "COMPLETED", force: true)
      center?.remove(contentId: contentId)
    }

    private func fail() {
      guard !finished else { return }
      finished = true
      emit(status: "FAILED", force: true)
      center?.remove(contentId: contentId)
    }

    func pause() { tasks.forEach { $0.suspend() } }
    func resumeAll() { tasks.forEach { $0.resume() } }
    func cancel() {
      tasks.forEach { $0.cancel() }
      session?.invalidateAndCancel()
    }
  }

  private var jobs: [String: Job] = [:]
  private let lock = NSLock()

  private func parsePages(args: [String: Any]) -> [Page] {
    if let raw = args["perPagePayload"] as? String,
       let data = raw.data(using: .utf8),
       let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]],
       !arr.isEmpty {
      return arr.compactMap { d -> Page? in
        guard let n = (d["pageNumber"] as? NSNumber)?.intValue,
              let u = d["url"] as? String else { return nil }
        var h = (d["headers"] as? [String: String]) ?? [:]
        if let r = d["referer"] as? String, !r.isEmpty, h["Referer"] == nil { h["Referer"] = r }
        return Page(number: n, url: u, headers: h)
      }
    }
    // v1 legacy: flat URL list numbered from startPage.
    let urls = args["imageUrls"] as? [String] ?? []
    let start = (args["startPage"] as? NSNumber)?.intValue ?? 1
    var global = (args["headers"] as? [String: String]) ?? [:]
    if let cookies = args["cookies"] as? [String: String], !cookies.isEmpty {
      global["Cookie"] = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    } else if let cookiesStr = args["cookies"] as? String, !cookiesStr.isEmpty {
      global["Cookie"] = cookiesStr
    }
    return urls.enumerated().map { i, u in Page(number: start + i, url: u, headers: global) }
  }

  private func headersFor(args: [String: Any]) -> [String: String] {
    if let h = args["headers"] as? [String: String] { return h }
    if let raw = args["headers"] as? String,
       let data = raw.data(using: .utf8),
       let h = (try? JSONSerialization.jsonObject(with: data)) as? [String: String] { return h }
    return [:]
  }

  func start(args: [String: Any]) -> String {
    guard let contentId = args["contentId"] as? String,
          let dest = args["destinationPath"] as? String, !dest.isEmpty else { return "" }
    lock.lock()
    if let existing = jobs[contentId] {
      lock.unlock()
      existing.resumeAll()
      return contentId
    }
    lock.unlock()
    var pages = parsePages(args: args)
    let global = headersFor(args: args)
    if !global.isEmpty {
      pages = pages.map { p in
        var h = global
        p.headers.forEach { h[$0.key] = $0.value }
        return Page(number: p.number, url: p.url, headers: h)
      }
    }
    let imagesDir = URL(fileURLWithPath: dest).appendingPathComponent("images", isDirectory: true)
    try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    let timeout = Double((args["imageTimeoutMs"] as? NSNumber)?.intValue ?? 60000) / 1000.0
    let maxParallel = (args["maxParallelImages"] as? NSNumber)?.intValue ?? 3
    let job = Job(contentId: contentId, pages: pages, imagesDir: imagesDir,
                  timeout: max(timeout, 5), center: self)
    lock.lock()
    jobs[contentId] = job
    lock.unlock()
    job.start(maxParallel: maxParallel)
    return contentId
  }

  func pause(contentId: String) {
    lock.lock(); let job = jobs[contentId]; lock.unlock()
    job?.pause()
  }

  func cancel(contentId: String) {
    lock.lock(); let job = jobs.removeValue(forKey: contentId); lock.unlock()
    job?.cancel()
  }

  func remove(contentId: String) {
    lock.lock(); jobs.removeValue(forKey: contentId); lock.unlock()
  }

  func status(contentId: String) -> [String: Any] {
    lock.lock(); let job = jobs[contentId]; lock.unlock()
    guard let job = job else {
      return ["contentId": contentId, "state": "IDLE", "downloadedPages": 0, "totalPages": 0]
    }
    return ["contentId": contentId, "state": "DOWNLOADING",
            "downloadedPages": job.done.count, "totalPages": job.pages.count]
  }

  func files(contentId: String, in dest: String?) -> [String] {
    guard let dir = imagesDir(contentId: contentId, in: dest) else { return [] }
    let exts = ["jpg", "jpeg", "png", "webp", "gif", "bmp", "avif"]
    let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    return files.filter { n in exts.contains((n as NSString).pathExtension.lowercased()) }
      .sorted().map { dir.appendingPathComponent($0).path }
  }

  func count(contentId: String, in dest: String?) -> Int { files(contentId: contentId, in: dest).count }

  func path(contentId: String, in dest: String?) -> String? {
    imagesDir(contentId: contentId, in: dest)?.path
  }

  func delete(contentId: String, dirPath: String?) {
    if let dirPath = dirPath, !dirPath.isEmpty {
      try? FileManager.default.removeItem(atPath: dirPath)
      return
    }
  }

  private func imagesDir(contentId: String, in dest: String?) -> URL? {
    // Destination is tracked per active job; nothing persisted for finished ones.
    lock.lock()
    defer { lock.unlock() }
    _ = jobs[contentId]
    guard let dest = dest, !dest.isEmpty else { return nil }
    return URL(fileURLWithPath: dest).appendingPathComponent("images", isDirectory: true)
  }
}

/// EventChannel sink for download progress.
final class KuronDownloadEvents: NSObject, FlutterStreamHandler {
  static let shared = KuronDownloadEvents()
  private var sink: FlutterEventSink?
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
  static func send(_ event: [String: Any]) {
    DispatchQueue.main.async { shared.sink?(event) }
  }
}
