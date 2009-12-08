package org.openzoom.flash.renderers.images
{
	import flash.display.BitmapData;
	
	import org.openzoom.flash.utils.ICacheItem;

	internal final class SourceThumbnail implements ICacheItem
	{
		include "../../core/Version.as";
		
		public var url:String;
    	public var bitmapData:BitmapData;
    	public var lastAccessTime:int = 0;
    	private var owners:Array = [];
		
		public function SourceThumbnail(url:String, bitmapData:BitmapData)
		{
			this.url = url;
			this.bitmapData = bitmapData;
		}	
	
	    public function addOwner(owner:Thumbnail):void
	    {
	        if (owners.indexOf(owner) > 0)
	        {
	            return;
	        }
	
	        owners.push(owner);
	    }

		public function compareTo(other:*):int
		{
			return 0;
		}
		
		public function dispose():void
		{
	        for each (var thumbnail:Thumbnail in owners)
	            thumbnail.dispose();
	
	        url = null;
	        bitmapData = null;
	        lastAccessTime = 0;
		}		
	}
}