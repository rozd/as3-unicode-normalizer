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
	import flash.utils.ByteArray;

	public class Normalizer
	{
		//----------------------------------------------------------------------
		//
		//	Class constants
		//
		//----------------------------------------------------------------------
		
		/**
		 * Mask for the compatibility form selectors.
		 */
		internal static const COMPATIBILITY_MASK:uint = 1;
		
		/**
		 * Mask for the composition form selectors.
		 */
		internal static const COMPOSITION_MASK:uint = 2;
		
		/**
		 * Represents Normalization Form D (NFD)
		 * 
		 * <p><b>Description</b>: Canonical Decomposition</i></p>
		 * 
		 * @see http://unicode.org/reports/tr15/ UNICODE NORMALIZATION FORMS
		 */
		public static const D:uint = 0;
		
		/**
		 * Represents Normalization Form C (NFC)
		 * 
		 * <p><b>Description</b>: Canonical Decomposition, followed by Canonical 
		 * Composition</i></p>
		 * 
		 * @see http://unicode.org/reports/tr15/ UNICODE NORMALIZATION FORMS
		 */
		public static const C:uint = COMPOSITION_MASK;
		
		/**
		 * Normalization Form KD (NFKD)
		 * 
		 * <p><b>Description</b>: Compatibility Decomposition</i></p>
		 * 
		 * @see http://unicode.org/reports/tr15/ UNICODE NORMALIZATION FORMS
		 */
		public static const KD:uint = COMPATIBILITY_MASK;
		
		/**
		 * Normalization Form KC (NFKC)
		 * 
		 * <p><b>Description</b>: Compatibility Decomposition, followed by 
		 * Canonical Composition</i></p>
		 * 
		 * @see http://unicode.org/reports/tr15/ UNICODE NORMALIZATION FORMS
		 */
		public static const KC:uint = COMPATIBILITY_MASK + COMPOSITION_MASK;
		
		//----------------------------------------------------------------------
		//
		//	Class variables
		//
		//----------------------------------------------------------------------
		
		/**
		 * Contains normalization data from the Unicode Character Database.
		 * use false for the minimal set, true for the real set.
		 */
		private static var data:NormalizerData = null;
		
		//----------------------------------------------------------------------
		//
		//	Constructor
		//
		//----------------------------------------------------------------------
		
		/**
		 * Create a normalizer for a given form.
		 */
		public function Normalizer(form:uint, fullData:Boolean)
		{
			this.form = form;
			
			if (data == null) 
				data = NormalizerBuilder.build(fullData); // load 1st time
		}
		
		//----------------------------------------------------------------------
		//
		//	Variables
		//
		//----------------------------------------------------------------------
		
		/**
		 * The current form.
		 */
		private var form:uint;
		
		//----------------------------------------------------------------------
		//
		//	Methods
		//
		//----------------------------------------------------------------------
		
		/**
		 * Normalizes text according to the chosen form
		 * 
		 * @param   source      the original text, unnormalized
		 * @return  target      the resulting normalized text
		 */
		public function normalize(source:String):String
		{
			var target:String = "";
			
			if (source.length != 0)
			{
				target = this.internalDecompose(source);
				
				if ((form & COMPOSITION_MASK) != 0)
				{
					target = this.internalCompose(target);
				}
			}
			
			return target;
		}
		
		//-----------------------------------
		//	Methods: Internal
		//-----------------------------------
		
		/**
		 * Decomposes text, either canonical or compatibility,
		 * replacing contents of the target buffer.
		 * @param   form        the normalization form. If COMPATIBILITY_MASK
		 *                      bit is on in this byte, then selects the recursive
		 *                      compatibility decomposition, otherwise selects
		 *                      the recursive canonical decomposition.
		 * @param   source      the original text, unnormalized
		 * @param   target      the resulting normalized text
		 */
		private function internalDecompose(source:String):String
		{
			var target:String = "";
			
			var buffer:String = "";
			
			var canonical:Boolean = (form & COMPATIBILITY_MASK) == 0;
			
			var ch32:int;
			
			for (var i:int = 0; i < source.length; i += UTF16.getCharCount(ch32))
			{
				buffer = "";
				
				ch32 = source.charCodeAt(i);
				
				buffer = data.getRecursiveDecomposition(canonical, ch32, buffer);
				
				// add all of the characters in the decomposition.
				// (may be just the original character, if there was
				// no decomposition mapping)
				
				var ch:int;
				for (var j:int = 0; j < buffer.length; j += UTF16.getCharCount(ch))
				{
					ch = buffer.charCodeAt(j);
					
					var chClass:int = data.getCanonicalClass(ch);
					
					var k:int = target.length; // insertion point
					
					if (chClass != 0)
					{
						// bubble-sort combining marks as necessary
						
						var ch2:int;
						
						for (; k > 0; k -= UTF16.getCharCount(ch2))
						{
							ch2 = target.charCodeAt(k - 1);
							
							if (data.getCanonicalClass(ch2) <= chClass) 
								break;
						}
					}
					
					target += String.fromCharCode(ch);
				}
			}
			
			return target;
		}
		
		/**
		 * Composes text in place. Target must already
		 * have been decomposed.
		 * @param   target      input: decomposed text.
		 *                      output: the resulting normalized text.
		 */
		private function internalCompose(target:String):String
		{
			var starterPos:int = 0;
			var starterCh:int = target.charCodeAt(0);
			var compPos:int = UTF16.getCharCount(starterCh); // length of last composition
			var lastClass:int = data.getCanonicalClass(starterCh);
			
			if (lastClass != 0) 
				lastClass = 256; // fix for strings staring with a combining mark
			
			var oldLen:int = target.length;
			
			// Loop on the decomposed characters, combining where possible
			
			var ch:int;
			
			for (var decompPos:int = compPos; decompPos < target.length; decompPos += UTF16.getCharCount(ch))
			{
				ch = UTF16.charAt(target, decompPos);
				var chClass:int = data.getCanonicalClass(ch);
				var composite:int = data.getPairwiseComposition(starterCh, ch);
				
				if (composite != NormalizerData.NOT_COMPOSITE && (lastClass < chClass || lastClass == 0))
				{
					target = UTF16.setCharAt(target, starterPos, composite);
					
					// we know that we will only be replacing non-supplementaries by non-supplementaries
					// so we don't have to adjust the decompPos
					starterCh = composite;
				} 
				else 
				{
					if (chClass == 0)
					{
						starterPos = compPos;
						starterCh  = ch;
					}
					
					lastClass = chClass;
					target = UTF16.setCharAt(target, compPos, ch);
					
					if (target.length != oldLen)
					{
						// MAY HAVE TO ADJUST!
						decompPos += target.length - oldLen;
						oldLen = target.length;
					}
					
					compPos += UTF16.getCharCount(ch);
				}
			}
			
			return target.substr(0, compPos);
		}
		
		/**
		 * Just accessible for testing.
		 */
		internal function getExcluded(ch:int):Boolean
		{
			return data.getExcluded(ch);
		}
		
		/**
		 * Just accessible for testing.
		 */
		internal function getRawDecompositionMapping(ch:int):String
		{
			return data.getRawDecompositionMapping(ch);
		}
	}
}