package org.openzoom.flash.descriptors
{
	public interface IThumbnailDescriptor
	{
		/**
		* Returns the url where the thumbnail resides.
		*/
		function getThumbnailURL():String;
		
		/**
		 * Determines if a thumbnail exists for this image.
		 */
		function existsThumbnail():Boolean;
		
		/**
		 * Returns the width of the thumbnail.
		 */
		function get thumbnailWidth():Number;
		
		/**
		 * Returns the height of the thumbnail. 
		 */
		function get thumbnailHeight():Number;
	}
}