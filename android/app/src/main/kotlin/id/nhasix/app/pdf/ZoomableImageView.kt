package id.nhasix.app.pdf

import android.content.Context
import android.graphics.Matrix
import android.graphics.PointF
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import androidx.appcompat.widget.AppCompatImageView
import kotlin.math.max
import kotlin.math.min

/**
 * Custom ImageView with zoom and pan support for PDF pages
 */
class ZoomableImageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : AppCompatImageView(context, attrs, defStyleAttr) {

    private val imageMatrix = Matrix()
    private var scaleFactor = 1f
    private val translation = PointF(0f, 0f)
    
    private val minScale = 1f
    private val maxScale = 5f
    private val doubleTapScale = 2f
    
    private var isZoomed = false
    
    private val scaleDetector: ScaleGestureDetector
    private val gestureDetector: GestureDetector
    
    private var lastTouchX = 0f
    private var lastTouchY = 0f
    private var activePointerId = MotionEvent.INVALID_POINTER_ID

    init {
        scaleType = ScaleType.MATRIX
        
        scaleDetector = ScaleGestureDetector(context, ScaleListener())
        gestureDetector = GestureDetector(context, GestureListener())
    }

    override fun setImageBitmap(bm: android.graphics.Bitmap?) {
        super.setImageBitmap(bm)
        // Reset zoom and center image when new bitmap is set
        if (bm != null) {
            resetZoom()
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        // Update matrix when layout changes (e.g., orientation change, mode toggle)
        if (changed && drawable != null) {
            updateMatrix()
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        scaleDetector.onTouchEvent(event)
        gestureDetector.onTouchEvent(event)
        
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                lastTouchX = event.x
                lastTouchY = event.y
                activePointerId = event.getPointerId(0)
            }
            
            MotionEvent.ACTION_MOVE -> {
                if (scaleFactor > 1f) {
                    val pointerIndex = event.findPointerIndex(activePointerId)
                    if (pointerIndex != -1) {
                        val x = event.getX(pointerIndex)
                        val y = event.getY(pointerIndex)
                        
                        if (!scaleDetector.isInProgress) {
                            val dx = x - lastTouchX
                            val dy = y - lastTouchY
                            
                            translation.x += dx
                            translation.y += dy
                            
                            // Constrain translation
                            constrainTranslation()
                            
                            updateMatrix()
                        }
                        
                        lastTouchX = x
                        lastTouchY = y
                    }
                    
                    // Prevent parent from intercepting touch when zoomed
                    parent?.requestDisallowInterceptTouchEvent(true)
                } else {
                    // Allow parent to handle scroll when not zoomed
                    parent?.requestDisallowInterceptTouchEvent(false)
                }
            }
            
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                activePointerId = MotionEvent.INVALID_POINTER_ID
                parent?.requestDisallowInterceptTouchEvent(false)
            }
        }
        
        return true
    }

    private inner class ScaleListener : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
            scaleFactor *= detector.scaleFactor
            scaleFactor = max(minScale, min(scaleFactor, maxScale))
            
            isZoomed = scaleFactor > 1f
            
            updateMatrix()
            return true
        }
    }

    private inner class GestureListener : GestureDetector.SimpleOnGestureListener() {
        override fun onDoubleTap(e: MotionEvent): Boolean {
            if (scaleFactor > 1f) {
                // Reset zoom
                resetZoom()
            } else {
                // Zoom to double
                scaleFactor = doubleTapScale
                isZoomed = true
                
                // Center on tap point
                val focusX = e.x
                val focusY = e.y
                translation.x = width / 2f - focusX * scaleFactor
                translation.y = height / 2f - focusY * scaleFactor
                
                constrainTranslation()
                updateMatrix()
            }
            return true
        }
        
        override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
            // Trigger click listener for parent (e.g., toggle controls)
            performClick()
            return true
        }
    }

    private fun updateMatrix() {
        if (drawable == null) return
        
        imageMatrix.reset()
        
        // Calculate scaled dimensions
        val drawableWidth = drawable.intrinsicWidth.toFloat()
        val drawableHeight = drawable.intrinsicHeight.toFloat()
        val scaledWidth = drawableWidth * scaleFactor
        val scaledHeight = drawableHeight * scaleFactor
        
        // If not zoomed (scale = 1), center the image like FIT_CENTER
        if (scaleFactor == 1f) {
            // Calculate scale to fit image in view
            val scaleX = width.toFloat() / drawableWidth
            val scaleY = height.toFloat() / drawableHeight
            val scale = minOf(scaleX, scaleY)
            
            // Calculate translation to center
            val scaledW = drawableWidth * scale
            val scaledH = drawableHeight * scale
            val dx = (width - scaledW) / 2f
            val dy = (height - scaledH) / 2f
            
            imageMatrix.postScale(scale, scale)
            imageMatrix.postTranslate(dx, dy)
        } else {
            // Zoomed mode - use custom scale and translation
            imageMatrix.postScale(scaleFactor, scaleFactor)
            imageMatrix.postTranslate(translation.x, translation.y)
        }
        
        setImageMatrix(imageMatrix)
    }

    private fun constrainTranslation() {
        if (drawable == null) return
        
        val viewWidth = width.toFloat()
        val viewHeight = height.toFloat()
        val drawableWidth = drawable.intrinsicWidth * scaleFactor
        val drawableHeight = drawable.intrinsicHeight * scaleFactor
        
        // Constrain X
        if (drawableWidth > viewWidth) {
            val maxX = 0f
            val minX = viewWidth - drawableWidth
            translation.x = max(minX, min(translation.x, maxX))
        } else {
            translation.x = (viewWidth - drawableWidth) / 2f
        }
        
        // Constrain Y
        if (drawableHeight > viewHeight) {
            val maxY = 0f
            val minY = viewHeight - drawableHeight
            translation.y = max(minY, min(translation.y, maxY))
        } else {
            translation.y = (viewHeight - drawableHeight) / 2f
        }
    }

    fun resetZoom() {
        scaleFactor = 1f
        translation.set(0f, 0f)
        isZoomed = false
        updateMatrix()
        parent?.requestDisallowInterceptTouchEvent(false)
    }

    fun isCurrentlyZoomed(): Boolean = isZoomed
}
