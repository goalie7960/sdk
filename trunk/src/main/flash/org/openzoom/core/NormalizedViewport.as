////////////////////////////////////////////////////////////////////////////////
//
//  OpenZoom
//
//  Copyright (c) 2007–2008, Daniel Gasienica <daniel@gasienica.ch>
//  Copyright (c) 2008,      Zoomorama
//                           Olivier Gambier <viapanda@gmail.com>
//                           Daniel Gasienica <daniel@gasienica.ch>
//                           Eric Hubscher <erich@zoomorama.com>
//                           David Marteau <dhmarteau@gmail.com>
//  Copyright (c) 2007,      Rick Companje <rick@companje.nl>
//
//  OpenZoom is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenZoom is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with OpenZoom. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
package org.openzoom.core
{

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.openzoom.events.ViewportEvent;
import org.openzoom.utils.math.clamp;

//------------------------------------------------------------------------------
//
//  Events
//
//------------------------------------------------------------------------------

[Event(name="resize", type="org.openzoom.events.ViewportEvent")]
[Event(name="change", type="org.openzoom.events.ViewportEvent")]
[Event(name="changeComplete", type="org.openzoom.events.ViewportEvent")]

/**
 * IViewport implementation that is based on a normalized [0, 1] coordinate system.
 */
public class NormalizedViewport extends EventDispatcher
                                implements INormalizedViewport,
                                           IViewportContainer
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
    
    private static const DEFAULT_MIN_Z : Number = 0.001
    private static const DEFAULT_MAX_Z : Number = 10000000
    private static const BOUNDS_TOLERANCE : Number = 0.5

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
    public function NormalizedViewport( width : Number, height : Number,
                                        scene : IMultiScaleScene ) : void
    {
    	_viewportWidth = width
    	_viewportHeight = height
    	
        _scene = scene
        _scene.addEventListener( Event.RESIZE, scene_resizeHandler )
        validate()
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  z
    //----------------------------------

    private var _zoom : Number = 1;

    [Bindable(event="zoomChanged")]
    public function get zoom() : Number
    {
        return _zoom
    }

    public function set zoom( value : Number ) : void
    {
        zoomTo( value )
    }

    //----------------------------------
    //  minZ
    //----------------------------------

    private var _minZ : Number = DEFAULT_MIN_Z

    public function get minZoom() : Number
    {
        return _minZ
    }

    public function set minZoom( value : Number ) : void
    {
        _minZ = value
        validate()
    }

    //----------------------------------
    //  maxZ
    //----------------------------------
    
    private var _maxZ : Number = DEFAULT_MAX_Z
    
    public function get maxZoom() : Number
    {
        return _maxZ
    }
    
    public function set maxZoom( value : Number ) : void
    {
       _maxZ = value
       validate()
    }

    //----------------------------------
    //  scale
    //----------------------------------

    [Bindable(event="scaleChanged")]
    public function get scale() : Number
    {
        return viewportWidth / ( scene.sceneWidth * width ) 
    }
 
    //----------------------------------
    //  transform
    //----------------------------------

//    public function get transform() : IViewportTransform
//    {
//    	return null
//    }
//
//    public function set transform( value : IViewportTransform ) : void
//    {
//    	// TODO
//    }
    
    //----------------------------------
    //  scene
    //----------------------------------

    private var _scene : IMultiScaleScene

    public function get scene() : IMultiScaleScene
    {
        return _scene
    }
    
    //----------------------------------
    //  viewportWidth
    //----------------------------------
    
    private var _viewportWidth : Number
    
    [Bindable(event="viewportWidthChanged")]
    public function get viewportWidth() : Number
    {
        return _viewportWidth
    }
    
    //----------------------------------
    //  viewportHeight
    //----------------------------------
    
    private var _viewportHeight : Number
    
    [Bindable(event="viewportHeightChanged")]
    public function get viewportHeight() : Number
    {
        return _viewportHeight
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Zooming
    //
    //--------------------------------------------------------------------------

    public function zoomTo( zoom : Number,
                            originX : Number = 0.5,
                            originY : Number = 0.5,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        var oldZoom : Number = this.zoom

        // keep z within min/max range
        _zoom = clamp( zoom, minZoom, maxZoom )

        // remember old origin
        var oldOrigin : Point = getViewportOrigin( originX, originY )

        // Compute normalized dimensions aspect ratio
        // This is ratio of the normalized content width and height 
        var ratio : Number = sceneAspectRatio / aspectRatio

        if( ratio >= 1 )
        {
            // content is wider than viewport
            _width = 1 / _zoom
            _height  = _width * ratio
        }
        else
        {
            // content is taller than viewport
            _height = 1 / _zoom
            _width  = _height / ratio
        }

        // move new origin to old origin
        moveOriginTo( oldOrigin.x, oldOrigin.y, originX, originY, false )

        if( dispatchChangeEvent )
            this.dispatchChangeEvent( oldZoom )
            
        dispatchEvent( new Event( "zoomChanged" ))
        dispatchEvent( new Event( "widthChanged" ))
        dispatchEvent( new Event( "heightChanged" ))
        dispatchEvent( new Event( "scaleChanged" ))
    }

    public function zoomBy( factor : Number,
                            originX : Number = 0.5, originY : Number = 0.5,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        zoomTo( zoom * factor, originX, originY, dispatchChangeEvent )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Panning
    //
    //--------------------------------------------------------------------------

    public function moveTo( x : Number, y : Number,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        // store the given (normalized) coordinates
        _x = x
        _y = y
    
        // content is wider than viewport
//        if( _width < 1 )
//        {
            // horizontal bounds checking:
            // the viewport sticks out on the left:
            // align it with the left margin
            if( _x + _width * BOUNDS_TOLERANCE < 0 )
                _x = -_width * BOUNDS_TOLERANCE
    
           // the viewport sticks out on the right:
           // align it with the right margin
           if(( _x + _width * ( 1 - BOUNDS_TOLERANCE )) > 1 )
               _x = 1 - _width * ( 1 - BOUNDS_TOLERANCE )      
//        }
//        else
//        {
//            // viewport is wider than content:
//            // center scene horizontally
//            _x = ( 1 - _width ) * 0.5
//        }
    
        // scene is taller than viewport
//        if( _height < 1 )
//        {
            // vertical bounds checking:
            // the viewport sticks out at the top:
            // align it with the top margin
            if( _y + _height * BOUNDS_TOLERANCE < 0 )
             _y = -_height * BOUNDS_TOLERANCE
        
            // the viewport sticks out at the bottom:
            // align it with the bottom margin
            if( _y + _height * (1 - BOUNDS_TOLERANCE) > 1 )
              _y = 1 - _height * ( 1 - BOUNDS_TOLERANCE )
//        }
//        else
//        {
//            // viewport is taller than scene
//            // center scene vertically
//            _y = ( 1 - _height ) * 0.5
//        } 
        
        if( dispatchChangeEvent )
            this.dispatchChangeEvent()
    }


    public function moveBy( dx : Number, dy : Number,
                            dispatchChangeEvent : Boolean = true  ) : void
    {
        moveTo( x + dx, y + dy, dispatchChangeEvent )
    }

    public function moveCenterTo( x : Number, y : Number,
                                  dispatchChangeEvent : Boolean = true ) : void
    {
        moveOriginTo( x, y, 0.5, 0.5, dispatchChangeEvent )
    }

    public function showRect( rect : Rectangle, scale : Number = 1.0, 
                              dispatchChangeEvent : Boolean = true ) : void
    {
    	// TODO: Implement for normalized coordinate system
    	var area : Rectangle = denormalizeRectangle( rect )
    	
        var centerX : Number = area.x + area.width  * 0.5
        var centerY : Number = area.y + area.height * 0.5
    
        var normalizedCenter : Point = new Point( centerX / scene.sceneWidth,
                                                  centerY / scene.sceneHeight )
                                                 
        var scaledWidth : Number = area.width / scale
        var scaledHeight : Number = area.height / scale
    
        var ratio : Number = sceneAspectRatio / aspectRatio
     
        // We have be careful here, the way the zoom factor is
        // interpreted depends on the relative ratio of scene and viewport
        if( scaledWidth > ( aspectRatio * scaledHeight ) )
        {
            // Area must fit horizontally in the viewport
            ratio = ( ratio < 1 ) ? ( scene.sceneWidth / ratio ) : scene.sceneWidth
            ratio = ratio / scaledWidth
        }
        else
        {
            // Area must fit vertically in the viewport  
            ratio = ( ratio > 1 ) ? ( scene.sceneHeight * ratio ) : scene.sceneHeight
            ratio = ratio / scaledHeight
        }
    
        var oldZoom : Number = zoom
    
        zoomTo( ratio, 0.5, 0.5, false )
        moveCenterTo( normalizedCenter.x, normalizedCenter.y, false )
    
        if( dispatchChangeEvent )
            this.dispatchChangeEvent( oldZoom )
    }
    
    public function showAll() : void
    {
    	var area : Rectangle = new Rectangle( 0, 0, scene.sceneWidth, scene.sceneHeight )
        showRect( normalizeRectangle( area ))
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate transformations
    //
    //--------------------------------------------------------------------------

    public function localToScene( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( x * scene.sceneWidth ) 
              + ( point.x / viewportWidth )  * ( width  * scene.sceneWidth )
        p.y = ( y * scene.sceneHeight )
              + ( point.y / viewportHeight ) * ( height * scene.sceneHeight )
        return p
    }

    public function sceneToLocal( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( point.x - ( x  * scene.sceneWidth ))
              / ( width  * scene.sceneWidth ) * viewportWidth
        p.y = ( point.y - ( y  * scene.sceneHeight ))
              / ( height * scene.sceneHeight ) * viewportHeight
        return p
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Internal
    //
    //--------------------------------------------------------------------------

    private function moveOriginTo( x : Number, y : Number,
                                   originX : Number, originY : Number,
                                   dispatchChangeEvent : Boolean = true ) : void
    {
        var newX : Number = x - width * originX
        var newY : Number = y - height * originY

        moveTo( newX, newY, dispatchChangeEvent )
    }

    private function getViewportOrigin( originX : Number,
                                        originY : Number ) : Point
    {
        var viewportOriginX : Number = x + width * originX
        var viewportOriginY : Number = y + height * originY
 
        return new Point( viewportOriginX, viewportOriginY )
    }

    /**
     * @private
     * 
     * Validate the viewport.
     */ 
    private function validate( dispatchEvent : Boolean = true ) : void
    {
        zoomTo( _zoom, 0.5, 0.5, dispatchEvent )
    }


    //--------------------------------------------------------------------------
    //
    //  Properties: Internal
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  aspectRatio
    //----------------------------------
    
    /**
     * @private 
     * Returns the aspect ratio of this Viewport object.
     */
    private function get aspectRatio() : Number
    {
        return viewportWidth / viewportHeight
    }
 
    //----------------------------------
    //  sceneAspectRatio
    //----------------------------------
    
    /**
     * @private 
     * Returns the aspect ratio of scene.
     */
    private function get sceneAspectRatio() : Number
    {
        return scene.sceneWidth / scene.sceneHeight
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: IViewport (scene coordinate system )
    //
    //--------------------------------------------------------------------------
    
    public function contains( x : Number, y : Number ) : Boolean
    {
        return ( x >= left ) && ( x <= right ) && ( y >= top ) && ( y <= bottom )
    }
    
    public function intersects( toIntersect : Rectangle ) : Boolean
    {
    	var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersects( denormalizeRectangle( toIntersect ))
    }
    
    public function intersection( toIntersect : Rectangle ) : Rectangle
    {
        var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersection( denormalizeRectangle( toIntersect ))
    }

    //--------------------------------------------------------------------------
    //
    //  Properties: IViewport
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  x
    //----------------------------------
    
    private var _x : Number = 0
    
    public function get x() : Number
    {
        return _x
    }
    
    public function set x( value : Number ) : void
    {
        moveTo( value, y )
    }
    
    //----------------------------------
    //  y
    //----------------------------------
    
    private var _y : Number = 0
    
    public function get y() : Number
    {
       return _y
    }
    
    public function set y( value : Number ) : void
    {
        moveTo( x, value )
    }
    
    //----------------------------------
    //  width
    //----------------------------------
    
    private var _width : Number = 1;
    
    [Bindable(event="widthChanged")]
    public function get width() : Number
    {
        return _width
    }
    
    //----------------------------------
    //  height
    //----------------------------------
    
    private var _height : Number = 1;
    
    [Bindable(event="heightChanged")]
    public function get height() : Number
    {
        return _height
    }
    
    //----------------------------------
    //  left
    //----------------------------------
    
    public function get left() : Number
    {
        return x
    }
    
    //----------------------------------
    //  right
    //----------------------------------
    
    public function get right() : Number
    {
        return x + width
    }
    
    //----------------------------------
    //  top
    //----------------------------------
    
    public function get top() : Number
    {
        return y
    }
    
    //----------------------------------
    //  bottom
    //----------------------------------
    
    public function get bottom() : Number
    {
        return y + height
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Events
    //
    //--------------------------------------------------------------------------
    
    private function dispatchChangeEvent( oldZoom : Number = NaN ) : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM,
                           false, false, isNaN( oldZoom ) ? zoom : oldZoom ))
    }
    
    public function beginTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_START ))
    }
    
    public function endTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_END ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Internal
    //
    //--------------------------------------------------------------------------
    
    public function setSize( width : Number, height : Number ) : void
    {
        if( _viewportWidth == width && _viewportHeight == height )
            return
        
        _viewportWidth = width
        _viewportHeight = height
        validate( false )
        
        dispatchEvent( new ViewportEvent( ViewportEvent.RESIZE, false, false, zoom ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate conversion
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */ 
    private function normalizeX( value : Number ) : Number
    {
        return value / scene.sceneWidth
    }

    /**
     * @private
     */
    private function normalizeY( value : Number ) : Number
    {
        return value / scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function normalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( normalizeX( value.x ),
                              normalizeY( value.y ),
                              normalizeX( value.width ),
                              normalizeY( value.height ))
    }
    
    /**
     * @private
     */
    private function normalizePoint( value : Point ) : Point
    {
        return new Point( normalizeX( value.x ),
                          normalizeY( value.y ))
    }
    
    /**
     * @private
     */ 
    private function denormalizeX( value : Number ) : Number
    {
        return value * scene.sceneWidth
    }

    /**
     * @private
     */
    private function denormalizeY( value : Number ) : Number
    {
        return value * scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function denormalizePoint( value : Point ) : Point
    {
        return new Point( denormalizeX( value.x ),
                          denormalizeY( value.y ))
    }
    
    /**
     * @private
     */
    private function denormalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( denormalizeX( value.x ),
                              denormalizeY( value.y ),
                              denormalizeX( value.width ),
                              denormalizeY( value.height ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------
    
    private function scene_resizeHandler( event : Event ) : void
    {
    	validate()
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Debug
    //
    //--------------------------------------------------------------------------
    
    override public function toString() : String
    {
        return "[NormalizedViewport]" + "\n"
               + "x=" + x + "\n" 
               + "y=" + y  + "\n"
               + "z=" + zoom + "\n"
               + "w=" + width + "\n"
               + "h=" + height + "\n"
               + "sW=" + scene.sceneWidth + "\n"
               + "sH=" + scene.sceneHeight
    }
}

}