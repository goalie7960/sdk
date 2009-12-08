package org.openzoom.flash.renderers.images
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.openzoom.flash.events.NetworkRequestEvent;
	import org.openzoom.flash.net.INetworkQueue;
	import org.openzoom.flash.net.INetworkRequest;
	import org.openzoom.flash.utils.ICache;

	internal final class ThumbnailLoader extends EventDispatcher
	{
		include "../../core/Version.as"
		
		private var owner:ThumbnailRenderManager;
		private var loader:INetworkQueue;
		private var cache:ICache;
		private var pending:Dictionary = new Dictionary();
		
		public function ThumbnailLoader(owner:ThumbnailRenderManager, loader:INetworkQueue, cache:ICache)
		{
			this.owner = owner;
			this.loader = loader;
			this.cache = cache;
		}
		
		public function loadThumbnail(thumbnail:Thumbnail):void
		{
			if(pending[thumbnail.url])
				return;
				
			pending[thumbnail.url] = true;

			var request:INetworkRequest = loader.addRequest(thumbnail.url, Bitmap, thumbnail);			
	        request.addEventListener(NetworkRequestEvent.COMPLETE, onRequestComplete, false, 0, true);	
	        request.addEventListener(NetworkRequestEvent.ERROR, onRequestError, false, 0, true);
	        
	        thumbnail.loading = true;
		}	
		
		private function onRequestComplete(e:NetworkRequestEvent):void
		{
			var thumbnail:Thumbnail = e.context as Thumbnail;
			var bitmap:BitmapData = Bitmap(e.data).bitmapData;
			
			var source:SourceThumbnail = new SourceThumbnail(thumbnail.url, bitmap);
			source.lastAccessTime = getTimer();
			
			cache.put(thumbnail.url, source);
			
			thumbnail.source = source;
			thumbnail.loading = false;
			
			pending[thumbnail.url] = false;
			
			owner.invalidateDisplayList();	
		}
		
		private function onRequestError(e:NetworkRequestEvent):void
		{
        	trace("[ThumbnailLoader] Thumbnail failed to load:", e.request.url);
        	
        	owner.invalidateDisplayList();
		}
	}
}