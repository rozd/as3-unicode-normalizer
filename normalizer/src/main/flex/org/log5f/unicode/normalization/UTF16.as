////////////////////////////////////////////////////////////////////////////////
//
//	Copyright (c) 2011 max.rozdobudko@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining
//	a copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//		
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

package org.log5f.unicode.normalization
{
	import mx.utils.StringUtil;

	public class UTF16
	{
		/**
		 * The minimum value for Supplementary code points
		 */
		public static const SUPPLEMENTARY_MIN_VALUE:int = 0x10000;

		/**
		 * Lead surrogate minimum value
		 */
		public static const LEAD_SURROGATE_MIN_VALUE:int = 0xD800;

		/**
		 * Lead surrogate maximum value
		 */
		public static const LEAD_SURROGATE_MAX_VALUE:int = 0xDBFF;

		/**
		 * Lead surrogate bitmask
		 */
		private static const LEAD_SURROGATE_BITMASK:int = 0xFFFFFC00;
		
		/**
		 * Lead surrogate bits
		 */
		private static const LEAD_SURROGATE_BITS:int = 0xD800;
		
		/**
		 * Trail surrogate maximum value
		 * 
		 * @stable ICU 2.1
		 */
		public static const TRAIL_SURROGATE_MAX_VALUE:int = 0xDFFF;
		
		/**
		 * Trail surrogate bitmask
		 */
		private static const TRAIL_SURROGATE_BITMASK:int = 0xFFFFFC00;
		
		/**
		 * Trail surrogate bits
		 */
		private static const TRAIL_SURROGATE_BITS:int = 0xDC00;
		
		/**
		 * Surrogate bitmask
		 */
		private static const SURROGATE_BITMASK:int = 0xFFFFF800;
		
		/**
		 * Surrogate bits
		 */
		private static const SURROGATE_BITS:int = 0xD800;
		
		//----------------------------------------------------------------------
		//
		//	Class methods
		//
		//----------------------------------------------------------------------
		
		public static function getCharCount(char32:int):int
		{
			return char32 < SUPPLEMENTARY_MIN_VALUE ? 1 : 2;
		}
		
		/**
		 * Extract a single UTF-32 value from a string. Used when iterating forwards or backwards (with
		 * <code>UTF16.getCharCount()</code>, as well as random access. If a validity check is
		 * required, use <code><a href="../lang/UCharacter.html#isLegal(char)">
		 * UCharacter.isLegal()</a></code>
		 * on the return value. If the char retrieved is part of a surrogate pair, its supplementary
		 * character will be returned. If a complete supplementary character is not found the incomplete
		 * character will be returned
		 * 
		 * @param source Array of UTF-16 chars
		 * @param offset16 UTF-16 offset to the start of the character.
		 * @return UTF-32 value for the UTF-32 value that contains the char at offset16. The boundaries
		 *         of that codepoint are the same as in <code>bounds32()</code>.
		 * @exception IndexOutOfBoundsException Thrown if offset16 is out of bounds.
		 */
		public static function charAt(source:String , offset16:int):int
		{
			return source.charCodeAt(offset16);
			
//			var single:int = source.charCodeAt(offset16);
//			
//			if (single < LEAD_SURROGATE_MIN_VALUE)
//			{
//				return single;
//			}
//			
//			return _charAt(source, offset16, single);
		}
		
		/**
		 * Set a code point into a UTF16 position. Adjusts target according if we are replacing a
		 * non-supplementary codepoint with a supplementary and vice versa.
		 * 
		 * @param target Stringbuffer
		 * @param offset16 UTF16 position to insert into
		 * @param char32 Code point
		 */
		public static function setCharAt(target:String, offset16:int, char32:int):String
		{
			var count:int = 1;
			var single:int = target.charCodeAt(offset16);
			
			if (isSurrogate(single))
			{
				// pairs of the surrogate with offset16 at the lead char found
				if (isLeadSurrogate(single) && (target.length > offset16 + 1)
					&& isTrailSurrogate(target.charCodeAt(offset16 + 1)))
				{
					count++;
				}
				else
				{
					// pairs of the surrogate with offset16 at the trail char
					// found
					if (isTrailSurrogate(single) && (offset16 > 0)
						&& isLeadSurrogate(target.charCodeAt(offset16 - 1)))
					{
						offset16--;
						count++;
					}
				}
			}
			
			return replaceAt(target, String.fromCharCode(char32), offset16, offset16 + count);
		}
		
		
		/**
		 * Determines whether the code value is a surrogate.
		 * 
		 * @param char16 The input character.
		 * @return true If the input character is a surrogate.
		 */
		public static function isSurrogate(char16:int):Boolean
		{
			return (char16 & SURROGATE_BITMASK) == SURROGATE_BITS;
		}
		
		/**
		 * Determines whether the character is a trail surrogate.
		 * 
		 * @param char16 The input character.
		 * @return true If the input character is a trail surrogate.
		 */
		public static function isTrailSurrogate(char16:int):Boolean
		{
			return (char16 & TRAIL_SURROGATE_BITMASK) == TRAIL_SURROGATE_BITS;
		}
		
		/**
		 * Determines whether the character is a lead surrogate.
		 * 
		 * @param char16 The input character.
		 * @return true If the input character is a lead surrogate
		 */
		public static function isLeadSurrogate(char16:int):Boolean
		{
			return (char16 & LEAD_SURROGATE_BITMASK) == LEAD_SURROGATE_BITS;
		}
		
		public static function replaceAt(string:String, value:*, beginIndex:int, endIndex:int):String
		{
			beginIndex = Math.max(beginIndex, 0);
			endIndex = Math.min(endIndex, string.length);
			var firstPart:String = string.substr(0, beginIndex);
			var secondPart:String = string.substr(endIndex, string.length);
			
			return (firstPart + value + secondPart);
		}
		
//		private static function _charAt(source:String, offset16:int, single:int):int
//		{
//			if (single > TRAIL_SURROGATE_MAX_VALUE)
//			{
//				return single;
//			}
//			
//			// Convert the UTF-16 surrogate pair if necessary.
//			// For simplicity in usage, and because the frequency of pairs is
//			// low, look both directions.
//			
//			if (single <= LEAD_SURROGATE_MAX_VALUE)
//			{
//				++offset16;
//				
//				if (source.length != offset16)
//				{
//					var trail:int = source.charAt(offset16);
//					
//					if (trail >= TRAIL_SURROGATE_MIN_VALUE && trail <= TRAIL_SURROGATE_MAX_VALUE)
//					{
//						return UCharacterProperty.getRawSupplementary(single, trail);
//					}
//				}
//			} else {
//				--offset16;
//				if (offset16 >= 0) {
//					// single is a trail surrogate so
//					char lead = source.charAt(offset16);
//					if (lead >= LEAD_SURROGATE_MIN_VALUE && lead <= LEAD_SURROGATE_MAX_VALUE) {
//						return UCharacterProperty.getRawSupplementary(lead, single);
//					}
//				}
//			}
//			return single; // return unmatched surrogate
//		}
	}
}