package org.openzoom.flash.components
{
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	import org.openzoom.flash.descriptors.IThumbnailDescriptor;
	import org.openzoom.flash.events.ViewportEvent;
	import org.openzoom.flash.net.NetworkQueue;
	import org.openzoom.flash.renderers.images.ThumbnailRenderManager;
	import org.openzoom.flash.renderers.images.ThumbnailRenderer;
	import org.openzoom.flash.utils.math.clamp;
	import org.openzoom.flash.viewport.INormalizedViewport;

	public final class ThumbnailSceneNavigator extends UIComponent
	{
		include "../core/Version.as"
	
	    //--------------------------------------------------------------------------
	    //
	    //  Class constants
	    //
	    //--------------------------------------------------------------------------
	
	    private static const DEFAULT_WINDOW_COLOR:uint = 0x666666;
	    private static const DEFAULT_WINDOW_BORDER:uint = 0xff0000;
	    private static const DEFAULT_WINDOW_ALPHA:Number = 0.5;
	    
	    //--------------------------------------------------------------------------
	    //
	    //  Variables
	    //
	    //--------------------------------------------------------------------------
	
	    private var background:Sprite;	
	    private var window:Sprite;
	
	    private var oldMouseX:Number;
	    private var oldMouseY:Number;
	
	    private var panning:Boolean = false;
	    
	    private var _renderManager:ThumbnailRenderManager;
	
	    //--------------------------------------------------------------------------
	    //
	    //  Constructor
	    //
	    //--------------------------------------------------------------------------

	    public function ThumbnailSceneNavigator():void
	    {	    	
	        addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    //  Properties
	    //
	    //--------------------------------------------------------------------------
	
	    private var _viewport:INormalizedViewport;
	
	    public function get viewport():INormalizedViewport
	    {
	        return _viewport;
	    }
	
	    public function set viewport(value:INormalizedViewport):void
	    {
	        if (value == viewport)
	            return;
	
	        _viewport = value;
	
	        if (viewport)
	        {
	            viewport.addEventListener(ViewportEvent.TRANSFORM_UPDATE, viewport_transformUpdateHandler, false, 0, true);
	            viewport.addEventListener(ViewportEvent.RESIZE, viewport_resizeHandler, false, 0, true);
	            viewport_transformUpdateHandler(null);
	
	            transformWindow();
	        }
	        else
	        {
	            viewport.removeEventListener(ViewportEvent.TRANSFORM_UPDATE, viewport_transformUpdateHandler);
	            viewport.removeEventListener(ViewportEvent.RESIZE, viewport_resizeHandler);
	        }
	    }
	    
	    private var _source:IThumbnailDescriptor;
	    
	    public function set source(value:Object):void
	    {
	    	if(_source)
	    	{
	    		_source = null;
	    		
	    		if(background && window)
	    		{
		    		if (background.numChildren > 0)
		    		{
		    			var renderer:ThumbnailRenderer = background.getChildAt(0) as ThumbnailRenderer;
		    			if(renderer)
		    			{
		    				_renderManager.removeRenderer();
		       			}
		      		}
		      		
					removeChild(background);
					removeChild(window);
					
					background = null;
					window = null;
	    		}
	    	}
	    	
	    	if(value is IThumbnailDescriptor)
	    	{	    		
	    		_source = value as IThumbnailDescriptor;
	    		dispatchEvent(new Event(Event.CHANGE));
	    		
				if(_source.existsThumbnail())
				{
					if(!background)
						createBackground(_source.thumbnailWidth, _source.thumbnailHeight);
						
					if(!window)
						createWindow(_source.thumbnailWidth, _source.thumbnailHeight);
						
					if(!_renderManager)
						_renderManager = new ThumbnailRenderManager(this, this.background, new NetworkQueue());
					
					visible = true;
								
			        var renderer:ThumbnailRenderer = new ThumbnailRenderer();
			        renderer.source = _source;
			        
					width = renderer.width;
					height = renderer.height;
			        
			        background.addChild(renderer);
			        _renderManager.addRenderer(renderer);
			        
			        dispatchEvent(new Event(Event.COMPLETE));
				}
				else
				{
					visible = false;
				}
	    	}
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    //  Methods: Children
	    //
	    //--------------------------------------------------------------------------
	
	    private function createBackground(width:Number, height:Number):void
	    {
	        background = new Sprite();
	
	        var g:Graphics = background.graphics;
            g.lineStyle(1.0, 0x000000, 0.8, false, LineScaleMode.NONE);
            g.beginFill(0xEFEFEF, 0.1);
            g.drawRect(0, 0, width, height);
            g.endFill();

            background.buttonMode = true
            background.addEventListener(MouseEvent.CLICK, background_clickHandler, false, 0, true);
	
	        addChildAt(background, 0);
	    }
	
	    private function createWindow(width:Number, height:Number):void
	    {
	        window = new Sprite();
	
	        var g:Graphics = window.graphics;
	        g.lineStyle(1.0, DEFAULT_WINDOW_BORDER);
            g.beginFill(DEFAULT_WINDOW_COLOR, DEFAULT_WINDOW_ALPHA);
            g.drawRect(0, 0, width, height);
            g.endFill();

            window.buttonMode = true;
            window.addEventListener(MouseEvent.MOUSE_DOWN, window_mouseDownHandler, false, 0, true);

            addChild(window);
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    //  Event handlers
	    //
	    //--------------------------------------------------------------------------
	
	    private function addedToStageHandler(event:Event):void
	    {
	        stage.addEventListener(Event.MOUSE_LEAVE, stage_mouseLeaveHandler, false, 0, true);
	        stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseLeaveHandler, false, 0, true);
	    }
	
	    private function viewport_transformUpdateHandler(event:ViewportEvent):void
	    {	    	
	        if (panning)
	           return;
	
	        transformWindow();
	    }
	
	    private function viewport_resizeHandler(event:ViewportEvent):void
	    {
	        transformWindow();
	    }
	
	    private function window_mouseDownHandler(event:MouseEvent):void
	    {
	        oldMouseX = stage.mouseX;
	        oldMouseY = stage.mouseY;
	
	        stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler, false, 0, true);
	        panning = true;
	    }
	
	    private function stage_mouseMoveHandler(event:MouseEvent):void
	    {
	        var dx:Number = stage.mouseX - oldMouseX;
	        var dy:Number = stage.mouseY - oldMouseY;
	
	        var targetX:Number = window.x + dx;
	        var targetY:Number = window.y + dy;
	
	        var windowBounds:Rectangle = window.getBounds(this);
	        var windowWidth:Number = windowBounds.width;
	        var windowHeight:Number = windowBounds.height;
	
	        if (targetX < 0)
	            targetX = 0;
	
	        if (targetY < 0)
	            targetY = 0;
	
	        if (windowBounds.right > background.width)
	            targetX = background.width - windowWidth;
	
	        if (windowBounds.bottom > background.height)
	            targetY = background.height - windowHeight;
	
	        window.x = targetX;
	        window.y = targetY;
	
	        oldMouseX = stage.mouseX;
	        oldMouseY = stage.mouseY;
	
	        viewport.panTo(
	        	clamp(window.x, 0, background.width) / background.width,
	            clamp(window.y, 0, background.height) / background.height);
	    }
	
	    private function stage_mouseUpHandler(event:MouseEvent):void
	    {
	        stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
	        panning = false;
	    }
	
	    private function background_clickHandler(event:MouseEvent):void
	    {
	        var transformX:Number = (background.scaleX * background.mouseX) / background.width;
	        var transformY:Number = (background.scaleY * background.mouseY) / background.height;
	
	        viewport.panCenterTo(transformX, transformY);
	    }
	
	    private function stage_mouseLeaveHandler(event:Event):void
	    {
	        stage_mouseUpHandler(null);
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    //  Methods
	    //
	    //--------------------------------------------------------------------------
	
	    private function transformWindow():void
	    {
	    	if(window && background)
	    	{	    		
		        // compute bounds
		        var v:INormalizedViewport = viewport;
		        var targetX:Number = clamp(v.x, 0, 1 - v.width) * background.width;
		        var targetY:Number = clamp(v.y, 0, 1 - v.height) * background.height;
		        var targetWidth:Number = clamp(v.width, 0, 1) * background.width;
		        var targetHeight:Number = clamp(v.height, 0, 1) * background.height;
		
		        // enable / disable window dragging
		        if (viewport.transformer.target.width >= 1 && viewport.transformer.target.height >= 1)
		            window.mouseEnabled = false;
		        else
		            window.mouseEnabled = true;
		
		        // transform
		        window.width = targetWidth;
		        window.height = targetHeight;
		        window.x = clamp(targetX, 0, background.width - window.width);
		        window.y = clamp(targetY, 0, background.height - window.height);
		    }
	  	}		
	}
}