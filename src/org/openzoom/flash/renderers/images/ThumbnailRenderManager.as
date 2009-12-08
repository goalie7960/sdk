package org.openzoom.flash.renderers.images
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	import org.openzoom.flash.descriptors.IThumbnailDescriptor;
	import org.openzoom.flash.net.INetworkQueue;
	import org.openzoom.flash.utils.Cache;
	import org.openzoom.flash.utils.IDisposable;

	public final class ThumbnailRenderManager implements IDisposable
	{
		include "../../core/Version.as"
		
		private static const MAX_CACHE_SIZE:uint = 10;
		
		private var renderer:ThumbnailRenderer;
		private var owner:Sprite;
		private var scene:Sprite;
		private var loader:INetworkQueue;
		private var cache:Cache;
		private var thumbnailLoader:ThumbnailLoader;		
		private var invalidateDisplayListFlag:Boolean = true;
		
		public function ThumbnailRenderManager(owner:Sprite, scene:Sprite, loader:INetworkQueue)
		{
			this.owner = owner;
			this.scene = scene;
			this.loader = loader;
			
			cache = new Cache(MAX_CACHE_SIZE);
			thumbnailLoader = new ThumbnailLoader(this, loader, cache);
		}
		
	    public function invalidateDisplayList():void
	    {
	        if (!invalidateDisplayListFlag)
	            invalidateDisplayListFlag = true;
	    }
	
	    public function validateDisplayList():void
	    {
	        if (invalidateDisplayListFlag)
	        {
	            invalidateDisplayListFlag = false;	            
	            updateDisplayList(renderer);
	        }
	    }
	    
	    private function updateDisplayList(renderer:ThumbnailRenderer):void
	    {	    	
	        // Abort if we're not visible
	        if (!renderer.visible)
	            return;
	            
	        var descriptor:IThumbnailDescriptor = renderer.source;
	
	        // Abort if we have no descriptor
	        if (!descriptor)
            	return;
	    		    	
	    	var thumbnail:Thumbnail = renderer.openzoom_internal::getThumbnail();
	    	
	    	if(!thumbnail)
	    		return;
	    		
	    	if(!thumbnail.source)
	    	{
	    		if(cache.contains(thumbnail.url))
	    		{
	    			var source:SourceThumbnail = cache.get(thumbnail.url) as SourceThumbnail;
	    			thumbnail.source = source;
	    			thumbnail.loading = false;
	    		}
	    	}
	    	
	    	if(!thumbnail.loaded)
	    	{
	            if (!thumbnail.loading)
	            {
	            	thumbnailLoader.loadThumbnail(thumbnail);
	            	invalidateDisplayList();
	            }
	            
	            return;
	    	}

			thumbnail.source.lastAccessTime = getTimer();
            
            var tileLayer:Shape = renderer.openzoom_internal::tileLayer;
	        var g:Graphics = tileLayer.graphics;
	        g.clear();	        
        	var textureMap:BitmapData = thumbnail.bitmapData;
            g.beginBitmapFill(textureMap, null, false, true);
            g.drawRect(0, 0, descriptor.thumbnailWidth, descriptor.thumbnailHeight);
        	g.endFill();
	    }
	    
	    public function addRenderer(renderer:ThumbnailRenderer):void
	    {	
	        if (!this.renderer)
	            owner.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
	
	        this.renderer = renderer;
	        invalidateDisplayList();
	    }
	    
	    public function removeRenderer():void
	    {
	        if(renderer)
	        {	
	        	renderer = null;
		    	owner.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	        }
	    }

		public function dispose():void
		{
	        owner = null;
	        loader = null;
	
	        cache.dispose();
	        cache = null;
		}
		
		private function onEnterFrame(e:Event):void
		{
			validateDisplayList();
		}		
	}
}