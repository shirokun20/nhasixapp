package id.nhasix.app.pdf

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.util.LruCache
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import id.nhasix.app.R
import kotlinx.coroutines.*
import java.io.File

/**
 * Vertical Continuous Scroll PDF Viewer (Webtoon Style)
 * Uses RecyclerView for 120Hz smooth scrolling and memory efficiency.
 */
class PdfReaderActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PDF_PATH = "pdf_path"
        const val EXTRA_PDF_TITLE = "pdf_title"
        const val EXTRA_START_PAGE = "start_page"

        fun createIntent(activity: Activity, pdfPath: String, title: String = "", startPage: Int = 0): Intent {
            return Intent(activity, PdfReaderActivity::class.java).apply {
                putExtra(EXTRA_PDF_PATH, pdfPath)
                putExtra(EXTRA_PDF_TITLE, title)
                putExtra(EXTRA_START_PAGE, startPage)
            }
        }
    }

    private lateinit var recyclerView: RecyclerView
    private lateinit var toolbar: com.google.android.material.appbar.MaterialToolbar
    private lateinit var appBarLayout: com.google.android.material.appbar.AppBarLayout
    private lateinit var pageIndicator: TextView
    private lateinit var loadingIndicator: ProgressBar
    private lateinit var btnToggleMode: android.widget.ImageButton

    private var pdfRenderer: PdfRenderer? = null
    private var fileDescriptor: ParcelFileDescriptor? = null
    private var totalPages = 0
    private var adapter: PdfPageAdapter? = null

    private var isVerticalMode = true // Default to Vertical (Webtoon)
    private var isControlsVisible = true

    // Coroutine scope for async rendering
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable Edge-to-Edge
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        setContentView(R.layout.activity_pdf_reader)

        // Initialize Views
        recyclerView = findViewById(R.id.pdfRecyclerView)
        toolbar = findViewById(R.id.toolbar)
        appBarLayout = findViewById(R.id.appBarLayout)
        pageIndicator = findViewById(R.id.pageIndicator)
        loadingIndicator = findViewById(R.id.loadingIndicator)
        btnToggleMode = findViewById(R.id.btnToggleMode)

        val pdfPath = intent?.getStringExtra(EXTRA_PDF_PATH)
        val title = intent?.getStringExtra(EXTRA_PDF_TITLE) ?: "PDF Document"
        val startPage = intent?.getIntExtra(EXTRA_START_PAGE, 0) ?: 0

        if (pdfPath == null) {
            finish()
            return
        }

        // Setup Toolbar
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setDisplayShowHomeEnabled(true)
        toolbar.title = title
        toolbar.setNavigationOnClickListener {
            finish()
        }

        btnToggleMode.setOnClickListener {
            toggleReadingMode()
        }
        
        openPdf(pdfPath, startPage)
    }

    private fun openPdf(path: String, startPage: Int) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) { finish() }
                    return@launch
                }

                fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                pdfRenderer = PdfRenderer(fileDescriptor!!)
                totalPages = pdfRenderer?.pageCount ?: 0

                withContext(Dispatchers.Main) {
                    setupRecyclerView(startPage)
                    updatePageIndicator(startPage)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) { finish() }
            }
        }
    }

    private fun setupRecyclerView(startPage: Int) {
        adapter = PdfPageAdapter(pdfRenderer!!, totalPages) {
            toggleControls()
        }
        recyclerView.adapter = adapter
        recyclerView.setHasFixedSize(true)
        recyclerView.setItemViewCacheSize(5)

        applyLayoutManager(startPage)

        // Scroll Listener for Indicator
        recyclerView.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                super.onScrolled(recyclerView, dx, dy)
                val layoutManager = recyclerView.layoutManager as? LinearLayoutManager
                val pos = layoutManager?.findFirstVisibleItemPosition() ?: RecyclerView.NO_POSITION
                if (pos != RecyclerView.NO_POSITION) {
                    updatePageIndicator(pos)
                }
            }
        })
    }

    private var snapHelper: androidx.recyclerview.widget.SnapHelper? = null

    private fun applyLayoutManager(targetPage: Int) {
        val layoutManager = LinearLayoutManager(this)
        layoutManager.orientation = if (isVerticalMode) RecyclerView.VERTICAL else RecyclerView.HORIZONTAL
        recyclerView.layoutManager = layoutManager
        
        // Remove existing SnapHelper
        snapHelper?.attachToRecyclerView(null)
        snapHelper = null
        recyclerView.onFlingListener = null // Ensure FlingListener is cleared
        
        if (!isVerticalMode) {
            // Horizontal Mode: Snap to pages
            snapHelper = androidx.recyclerview.widget.PagerSnapHelper()
            snapHelper?.attachToRecyclerView(recyclerView)
            
            // Icon: Rotate to indicate horizontal
            btnToggleMode.rotation = 90f 
        } else {
             // Vertical Mode: Default
             btnToggleMode.rotation = 0f
        }

        // Restore position
        if (targetPage >= 0) {
            recyclerView.scrollToPosition(targetPage)
        }
    }

    private fun toggleReadingMode() {
        val layoutManager = recyclerView.layoutManager as? LinearLayoutManager
        val currentPage = layoutManager?.findFirstVisibleItemPosition() ?: 0
        
        isVerticalMode = !isVerticalMode
        applyLayoutManager(currentPage)
        // Notify adapter to rebind views with correct layout params
        adapter?.notifyDataSetChanged()
    }

    private fun toggleControls() {
        isControlsVisible = !isControlsVisible
        val visibility = if (isControlsVisible) View.VISIBLE else View.GONE
        appBarLayout.visibility = visibility
        pageIndicator.visibility = visibility
    }

    private fun updatePageIndicator(pageIndex: Int) {
        pageIndicator.text = "${pageIndex + 1} / $totalPages"
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel() // Cancel all pending rendering jobs
        try {
            pdfRenderer?.close()
            fileDescriptor?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // --- Adapter ---

    inner class PdfPageAdapter(
        private val renderer: PdfRenderer,
        private val count: Int,
        private val onItemClick: () -> Unit
    ) : RecyclerView.Adapter<PdfPageViewHolder>() {

        private val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
        private val cacheSize = maxMemory / 4
        private val memoryCache = object : LruCache<Int, Bitmap>(cacheSize) {
            override fun sizeOf(key: Int, bitmap: Bitmap): Int {
                return bitmap.byteCount / 1024
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PdfPageViewHolder {
            val imageView = ImageView(parent.context).apply {
                scaleType = ImageView.ScaleType.FIT_CENTER
                adjustViewBounds = true
            }
            return PdfPageViewHolder(imageView)
        }

        override fun onBindViewHolder(holder: PdfPageViewHolder, position: Int) {
            // Adjust LayoutParams based on Mode
            if (isVerticalMode) {
                holder.imageView.layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            } else {
                holder.imageView.layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            }

            holder.imageView.setOnClickListener { onItemClick() }

            val cachedBitmap = memoryCache.get(position)
            
            if (cachedBitmap != null) {
                holder.imageView.setImageBitmap(cachedBitmap)
            } else {
                holder.imageView.setImageBitmap(null)
                holder.imageView.setBackgroundColor(0xFF222222.toInt())
                renderPageAsync(position, holder)
            }
        }

        private fun renderPageAsync(index: Int, holder: PdfPageViewHolder) {
            holder.currentPosition = index

            scope.launch(Dispatchers.Default) {
                if (holder.currentPosition != index) return@launch
                var bitmap: Bitmap? = null

                try {
                    synchronized(renderer) {
                        if (index >= count) return@launch
                        
                        renderer.openPage(index).use { page ->
                            val screenWidth = resources.displayMetrics.widthPixels
                            // Simple quality logic:
                            val srcWidth = page.width
                            val srcHeight = page.height
                            
                            val renderWidth = screenWidth
                            val renderHeight = (srcHeight * (screenWidth.toFloat() / srcWidth)).toInt()
                            
                            bitmap = Bitmap.createBitmap(
                                renderWidth,
                                renderHeight,
                                Bitmap.Config.ARGB_8888
                            )
                            
                            page.render(bitmap!!, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        }
                    }

                    if (bitmap != null) {
                        memoryCache.put(index, bitmap)
                        withContext(Dispatchers.Main) {
                            if (holder.currentPosition == index) {
                                holder.imageView.setImageBitmap(bitmap)
                                holder.imageView.background = null
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        override fun getItemCount(): Int = count
    }

    inner class PdfPageViewHolder(val imageView: ImageView) : RecyclerView.ViewHolder(imageView) {
        var currentPosition: Int = -1
    }
}
