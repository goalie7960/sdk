package org.openzoom.flash.renderers.images
{
	import flash.display.BitmapData;
	import flash.errors.IllegalOperationError;
	
	import org.openzoom.flash.utils.IComparable;
	import org.openzoom.flash.utils.IDisposable;

	internal class Thumbnail implements IDisposable, IComparable
	{
		include "../../core/Version.as";
		
		public var loading:Boolean = false;
		public var url:String;
		private var _source:SourceThumbnail;
		
		public function Thumbnail(url:String)
		{
			this.url = url;
		}
		
	    public function get bitmapData():BitmapData
	    {
	        if (source)
	           return source.bitmapData;
	
	        return null;
	    }
	    
	    public function get loaded():Boolean
	    {
	        if (bitmapData)
	           return true;
	
	        return false;
	    }
	
	    public function get source():SourceThumbnail
	    {
	        return _source;
	    }
	
	    public function set source(value:SourceThumbnail):void
	    {
	        if (!value)
	           throw new ArgumentError("[Thumbnail] Source cannot be null.")
	
	        _source = value;
	        _source.addOwner(this);
	    }
	    
	    public function get lastAccessTime():int
	    {
	        if (!source)
	            throw new IllegalOperationError("[Thumbnail] Source missing.");
	
	        return source.lastAccessTime;
	    }
	
	    public function set lastAccessTime(value:int):void
	    {
	        if (!source)
	            throw new IllegalOperationError("[Thumbnail] Source missing.");
	
	        source.lastAccessTime = value;
	    }

		public function dispose():void
		{
        	_source = null;
        	loading = false;
		}
		
		public function compareTo(other:*):int
		{
			return 0;
		}		
	}
}