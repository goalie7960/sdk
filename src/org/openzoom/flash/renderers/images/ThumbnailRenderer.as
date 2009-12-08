package org.openzoom.flash.renderers.images
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import org.openzoom.flash.core.openzoom_internal;
	import org.openzoom.flash.descriptors.IThumbnailDescriptor;
	import org.openzoom.flash.utils.IDisposable;
	
	use namespace openzoom_internal;

	public final class ThumbnailRenderer extends Sprite implements IDisposable
	{
		include "../../core/Version.as";
		
		private var _source:IThumbnailDescriptor;
		private var _height:Number = 0;
		private var _width:Number = 0;
		private var thumbnailCache:Dictionary = new Dictionary();
		openzoom_internal var tileLayer:Shape;
		
	    public function ThumbnailRenderer()
	    {
	        openzoom_internal::tileLayer = new Shape();
	        addChild(openzoom_internal::tileLayer);
	    }
	
	    public function get source():IThumbnailDescriptor
	    {
	        return _source;
	    }
	
	    public function set source(value:IThumbnailDescriptor):void
	    {
	        if (_source === value)
	           return;
	
	        _source = value;
	    }
	
	    override public function get width():Number
	    {
	        return _source.thumbnailWidth;
	    }
	
	    /*override public function set width(value:Number):void
	    {
	        if (value === _width)
	           return;
	
	        _width = value;

	        updateDisplayList(width, height);
	    }*/
	
	    override public function get height():Number
	    {
	        return _source.thumbnailHeight;
	    }
	
	    /*override public function set height(value:Number):void
	    {
	        if (value === _height)
	           return;
	
	        _height = value;
	
	        updateDisplayList(width, height);
	    }*/
	    
	    openzoom_internal function getThumbnail():Thumbnail
	    {
	    	var descriptor:IThumbnailDescriptor = _source as IThumbnailDescriptor;
	    	
	        if (!descriptor)
	           trace("[ThumbnailRenderer] getThumbnail: Source undefined");
	
	        if (!descriptor.existsThumbnail())
	            return null;	    	
	    	
	    	var url:String = descriptor.getThumbnailURL();
	        var thumbnail:Thumbnail = thumbnailCache[url];
	
	        if (!thumbnail)
	        {
	            thumbnail = new Thumbnail(url);
	            thumbnailCache[url] = thumbnail;
	        }
	
	        return thumbnail;
	    }
		
		public function dispose():void
		{
			thumbnailCache = null;
	        removeChild(openzoom_internal::tileLayer);
	        openzoom_internal::tileLayer = null;
		}		
	}
}