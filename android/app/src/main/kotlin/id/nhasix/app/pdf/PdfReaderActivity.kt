package id.nhasix.app.pdf

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.floatingactionbutton.FloatingActionButton
import id.nhasix.app.R
import java.io.File
import kotlin.math.max
import kotlin.math.min

/**
 * Full-screen PDF viewer using Android's PdfRenderer
 * Features:
 * - Smooth 60 FPS rendering
 * - Pinch-to-zoom
 * - Swipe to navigate pages
 * - Page indicator
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

    private lateinit var imageView: ImageView
    private lateinit var pageIndicator: TextView
    private lateinit var prevButton: FloatingActionButton
    private lateinit var nextButton: FloatingActionButton

    private var pdfRenderer: PdfRenderer? = null
    private var currentPage: PdfRenderer.Page? = null
    private var currentPageIndex = 0
    private var totalPages = 0

    // Zoom and pan variables
    private var scaleFactor = 1.0f
    private var translateX = 0f
    private var translateY = 0f

    private lateinit var scaleGestureDetector: ScaleGestureDetector
    private lateinit var gestureDetector: GestureDetector

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_pdf_reader)

        // Hide action bar for full-screen experience
        supportActionBar?.hide()

        // Initialize views
        imageView = findViewById(R.id.pdfImageView)
        pageIndicator = findViewById(R.id.pageIndicator)
        prevButton = findViewById(R.id.prevPageButton)
        nextButton = findViewById(R.id.nextPageButton)

        // Get PDF path from intent
        val pdfPath = intent?.getStringExtra(EXTRA_PDF_PATH)
        val title = intent?.getStringExtra(EXTRA_PDF_TITLE) ?: "PDF Document"
        currentPageIndex = intent?.getIntExtra(EXTRA_START_PAGE, 0) ?: 0

        if (pdfPath == null) {
            finish()
            return
        }

        // Setup gesture detectors
        scaleGestureDetector = ScaleGestureDetector(this, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                scaleFactor *= detector.scaleFactor
                scaleFactor = max(0.5f, min(scaleFactor, 5.0f))
                updateImageTransform()
                return true
            }
        })

        gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(
                e1: MotionEvent?,
                e2: MotionEvent,
                velocityX: Float,
                velocityY: Float
            ): Boolean {
                val diffX = e2.x - (e1?.x ?: 0f)
                
                if (Math.abs(diffX) > 100 && Math.abs(velocityX) > 100) {
                    if (diffX > 0) {
                        showPreviousPage()
                    } else {
                        showNextPage()
                    }
                    return true
                }
                return false
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                if (scaleFactor > 1.0f) {
                    resetTransform()
                } else {
                    scaleFactor = 2.0f
                    updateImageTransform()
                }
                return true
            }
        })

        imageView.setOnTouchListener { _, event ->
            scaleGestureDetector.onTouchEvent(event)
            gestureDetector.onTouchEvent(event)
            true
        }

        // Open PDF
        openPdfRenderer(pdfPath)

        // Setup navigation buttons
        prevButton.setOnClickListener { showPreviousPage() }
        nextButton.setOnClickListener { showNextPage() }

        // Setup title
        this.title = title
    }

    private fun openPdfRenderer(pdfPath: String) {
        try {
            val file = File(pdfPath)
            if (!file.exists()) {
                finish()
                return
            }

            val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            pdfRenderer = PdfRenderer(fileDescriptor)
            totalPages = pdfRenderer?.pageCount ?: 0

            if (totalPages > 0) {
                currentPageIndex = currentPageIndex.coerceIn(0, totalPages - 1)
                showPage(currentPageIndex)
            } else {
                finish()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            finish()
        }
    }

    private fun showPage(index: Int) {
        currentPage?.close()

        if (pdfRenderer == null) return

        currentPage = pdfRenderer?.openPage(index)
        currentPage?.let { page ->
            val bitmap = Bitmap.createBitmap(
                page.width * 2,
                page.height * 2,
                Bitmap.Config.ARGB_8888
            )

            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            imageView.setImageBitmap(bitmap)
            resetTransform()
            updatePageIndicator()
            updateNavigationButtons()
        }
    }

    private fun showNextPage() {
        if (currentPageIndex < totalPages - 1) {
            showPage(++currentPageIndex)
        }
    }

    private fun showPreviousPage() {
        if (currentPageIndex > 0) {
            showPage(--currentPageIndex)
        }
    }

    private fun updatePageIndicator() {
        pageIndicator.text = "${currentPageIndex + 1} / $totalPages"
    }

    private fun updateNavigationButtons() {
        prevButton.isEnabled = currentPageIndex > 0
        nextButton.isEnabled = currentPageIndex < totalPages - 1
        prevButton.alpha = if (currentPageIndex > 0) 1.0f else 0.5f
        nextButton.alpha = if (currentPageIndex < totalPages - 1) 1.0f else 0.5f
    }

    private fun resetTransform() {
        scaleFactor = 1.0f
        translateX = 0f
        translateY = 0f
        updateImageTransform()
    }

    private fun updateImageTransform() {
        imageView.scaleX = scaleFactor
        imageView.scaleY = scaleFactor
        imageView.translationX = translateX
        imageView.translationY = translateY
    }

    override fun onDestroy() {
        super.onDestroy()
        currentPage?.close()
        pdfRenderer?.close()
    }
}
