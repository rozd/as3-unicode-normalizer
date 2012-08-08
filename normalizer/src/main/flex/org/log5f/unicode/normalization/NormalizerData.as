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
	public class NormalizerData
	{
		/**
		 * Constant for use in getPairwiseComposition
		 */
		public static const NOT_COMPOSITE:int = 0xFFFF;
		
		//----------------------------------------------------------------------
		//
		//	Constructor
		//
		//----------------------------------------------------------------------
		
		/**
		 * Only accessed by NormalizerBuilder.
		 */
		public function NormalizerData(canonicalClass:IntHashtable, decompose:IntStringHashtable, 
			compose:IntHashtable, isCompatibility:Object, isExcluded:Object)
		{
				this.canonicalClass = canonicalClass;
				this.decompose = decompose;
				this.compose = compose;
				this.isCompatibility = isCompatibility;
				this.isExcluded = isExcluded;
		}
		
		//----------------------------------------------------------------------
		//
		//	Variables
		//
		//----------------------------------------------------------------------
		
		/**
		 * For now, just use IntHashtable
		 * Two-stage tables would be used in an optimized implementation.
		 */
		private var canonicalClass:IntHashtable;
		
		/**
		 * The main data table maps chars to a 32-bit int.
		 * It holds either a pair: top = first, bottom = second
		 * or singleton: top = 0, bottom = single.
		 * If there is no decomposition, the value is 0.
		 * Two-stage tables would be used in an optimized implementation.
		 * An optimization could also map chars to a small index, then use that
		 * index in a small array of ints.
		 */
		private var decompose:IntStringHashtable;
		
		/**
		 * Maps from pairs of characters to single.
		 * If there is no decomposition, the value is NOT_COMPOSITE.
		 */
		private var compose:IntHashtable;
		
		/**
		 * Tells whether decomposition is canonical or not.
		 */
		private var isCompatibility:Object = {};
		
		/**
		 * Tells whether character is script-excluded or not.
		 * Used only while building, and for testing.
		 */
		private var isExcluded:Object = {};
		
		//----------------------------------------------------------------------
		//
		//	Methods
		//
		//----------------------------------------------------------------------
		
		/**
		 * Just accessible for testing.
		 */
		internal function getExcluded(ch:int):Boolean
		{
			return isExcluded[ch];
		}
		
		/**
		 * Just accessible for testing.
		 */
		internal function getRawDecompositionMapping(ch:int):String
		{
			return decompose.get(ch);
		}
		
		/**
		 * Gets the combining class of a character from the
		 * Unicode Character Database.
		 * @param   ch      the source character
		 * @return          value from 0 to 255
		 */
		public function getCanonicalClass(ch:int):int
		{
			return canonicalClass.get(ch);
		}
		
		/**
		 * Returns the composite of the two characters. If the two
		 * characters don't combine, returns NOT_COMPOSITE.
		 * Only has to worry about BMP characters, since those are the only ones that can ever compose.
		 * @param   first   first character (e.g. 'c')
		 * @param   first   second character (e.g. 'ё' cedilla)
		 * @return          composite (e.g. 'з')
		 */
		public function getPairwiseComposition(first:int, second:int):int
		{
			if (first < 0 || first > 0x10FFFF || second < 0 || second > 0x10FFFF)
				return NOT_COMPOSITE;
			
			return compose.get((first << 16) | second) ;
		}
		
		/**
		 * Gets recursive decomposition of a character from the 
		 * Unicode Character Database.
		 * @param   canonical    If true
		 *                  bit is on in this byte, then selects the recursive 
		 *                  canonical decomposition, otherwise selects
		 *                  the recursive compatibility and canonical decomposition.
		 * @param   ch      the source character
		 * @param   buffer  buffer to be filled with the decomposition
		 */
		public function getRecursiveDecomposition(canonical:Boolean, ch:int, buffer:String):String
		{
			var decomp:String = decompose.get(ch);
			
			if (decomp != null && !(canonical && isCompatibility[ch]))
			{
				var n:int = decomp.length;
				for (var i:int = 0; i < n; ++i)
				{
					buffer += this.getRecursiveDecomposition(canonical, decomp.charCodeAt(i), buffer);
				}
			}
			else
			{
				// if no decomp, append
				return String.fromCharCode(ch);
			}
			
			return buffer;
		}
	}
}