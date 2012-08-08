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
	import mx.core.ByteArrayAsset;
	
	/**
	 * 
	 */
	public class NormalizerBuilder
	{
		//----------------------------------------------------------------------
		//
		//	Class constants
		//
		//----------------------------------------------------------------------
		
		[Embed(source="/data/UnicodeData-3.0.0.txt", mimeType="application/octet-stream")]
		/** @private */
		private static var UnicodeDataTXT:Class;

		[Embed(source="/data/CompositionExclusions-1.txt", mimeType="application/octet-stream")]
		/** @private */
		private static var CompositionExclusionsTXT:Class;
		
		/**
		 * Testing flags
		 */
		
		private static const DEBUG:Boolean = true;
		private static const GENERATING:Boolean = false;
		
		/**
		 * Hangul composition constants
		 */
		internal static const SBase:int = 0xAC00;
		internal static const LBase:int = 0x1100;
		internal static const VBase:int = 0x1161;
		internal static const TBase:int = 0x11A7;
		internal static const LCount:int = 19;
		internal static const VCount:int = 21;
		internal static const TCount:int = 28;
		internal static const NCount:int = VCount * TCount; // 588
		internal static const SCount:int = LCount * NCount; // 11172
		
		//----------------------------------------------------------------------
		//
		//	Class methods
		//
		//----------------------------------------------------------------------
		
		/**
		 * Called exactly once by NormalizerData to build the static data
		 */
		
		internal static function build(fullData:Boolean):NormalizerData
		{
			try 
			{
				var canonicalClass:IntHashtable = new IntHashtable(0);
				var decompose:IntStringHashtable = new IntStringHashtable(null);
				var compose:IntHashtable = new IntHashtable(NormalizerData.NOT_COMPOSITE);
				var isCompatibility:Object = {};
				var isExcluded:Object = {};
				
				if (fullData)
				{
//					trace("Building Normalizer Data from file.");
					readExclusionList(isExcluded);
//					trace(isExcluded[0x00C0]);
					buildDecompositionTables(canonicalClass, decompose, compose, 
						isCompatibility, isExcluded);
				}
				else
				{
					
//					trace("Building abridged data.");
				
					setMinimalDecomp(canonicalClass, decompose, compose, 
						isCompatibility, isExcluded);
				}
				
				return new NormalizerData(canonicalClass, decompose, compose, 
					isCompatibility, isExcluded);
			}
			catch (e:Error)
			{
//				trace("Can't load data file." + e + ", " + e);
			}
			
			return null;
		}
		
		// =============================================================
		// Building Decomposition Tables
		// =============================================================
		
		/**
		 * Reads exclusion list and stores the data
		 */
		private static function readExclusionList(isExcluded:Object):void
		{
//			if (DEBUG) 
//				trace("Reading Exclusions");
			
//			var bytes:ByteArrayAsset = ByteArrayAsset(new CompositionExclusionsTXT());
//			var input:String = bytes.readUTF();
			
			var input:String = Object(new CompositionExclusionsTXT()).toString();
			
			for each (var line:String in input.split("\n"))
			{
				// read a line, discarding comments and blank lines
				
				if (line == null) break;
				
				// strip comments
				
				var comment:int = line.indexOf('#');
				
				if (comment != -1) 
					line = line.substring(0, comment);
				
				// ignore blanks
				
				if (line.length == 0) 
					continue;
				
				// store -1 in the excluded table for each character hit
				
				var value:int = parseInt(line.substring(0, 4), 16);
				isExcluded[value] = true;
				
//				trace("Excluding " + hex(value));
			}
			
//			if (DEBUG) trace("Done reading Exclusions");
		}
		
		/**
		 * Builds a decomposition table from a UnicodeData file
		 */
		private static function buildDecompositionTables(canonicalClass:IntHashtable, decompose:IntStringHashtable, 
			compose:IntHashtable, isCompatibility:Object, isExcluded:Object):void
		{
//			if (DEBUG) 
//				trace("Reading Unicode Character Database");
			
			var input:String = Object(new UnicodeDataTXT()).toString();
			
			var value:int;
			var pair:int;
			var counter:int = 0;
			
			for each (var line:String in input.split("\n"))
			{
				// read a line, discarding comments and blank lines
				
				if (line == null) break;
				
				// strip comments
				
				var comment:int = line.indexOf('#'); 
				
				if (comment != -1) line = line.substring(0,comment);
				
				
				if (line.length == 0) continue;
				
				
				if (DEBUG)
				{
					counter++;
					
//					if ((counter & 0xFF) == 0) 
//						trace("At: " + line);
				}
				
				// find the values of the particular fields that we need
				// Sample line: 00C0;LATIN ...A GRAVE;Lu;0;L;0041 0300;;;;N;LATIN ... GRAVE;;;00E0;
				
				var start:int = 0;
				var end:int = line.indexOf(';'); // code
				value = parseInt(line.substring(start,end), 16);
				
				if (value == 0x00c0)
				{
//					trace("debug: " + line);
				}
				
				end = line.indexOf(';', start=end+1); // name
				var name:String = line.substring(start, end);
				end = line.indexOf(';', start=end+1); // general category
				end = line.indexOf(';', start=end+1); // canonical class
				
				// check consistency: canonical classes must be from 0 to 255
				
				var cc:int = parseInt(line.substring(start,end));
				
				if (cc != (cc & 0xFF)) 
					trace("Bad canonical class at: " + line);
				
				canonicalClass.put(value,cc);
				end = line.indexOf(';', start=end+1); // BIDI
				end = line.indexOf(';', start=end+1); // decomp
				
				// decomp requires more processing.
				// store whether it is canonical or compatibility.
				// store the decomp in one table, and the reverse mapping (from pairs) in another
				
				if (start != end)
				{
					var segment:String = line.substring(start, end);
					var compat:Boolean = segment.charAt(0) == '<';
					
					if (compat) 
						isCompatibility[value] = true;
					
					var decomp:String = fromHex(segment);
					
					// a small snippet of code to generate the Applet data
					
					if (GENERATING) 
					{
						if (value < 0xFF) 
						{
//							trace(
//								"\"\\u" + hex(value) + "\", "
//								+ "\"\\u" + hex(decomp, "\\u") + "\", "
//								+ (compat ? "\"K\"," : "\"\",")
//								+ "// " + name);
						}
					}
					
					// check consistency: all canon decomps must be singles or pairs!
					
					if (decomp.length < 1 || decomp.length > 2 && !compat)
					{
//						trace("Bad decomp at: " + line);
					}
					
					decompose.put(value, decomp);
					
					// only compositions are canonical pairs
					// skip if script exclusion
					
					if (!compat && !isExcluded[value])
					{
						var first:int = 0x0000;
						var second:int = decomp.charCodeAt(0);
						
						if (decomp.length > 1)
						{
							first = second;
							second = decomp.charCodeAt(1);
						}
						
						// store composition pair in single integer
						
						pair = (first << 16) | second;
						
						if (DEBUG && value == 0x00C0)
						{
//							trace("debug2: " + line);
						}
						
						compose.put(pair, value);
						
//						trace("Including: ", pair, compose.get(pair), decomp);
						
					}
					else if (DEBUG)
					{
//						trace("Excluding: " + decomp);
						
					}
				}
			}
			
//			if (DEBUG) trace("Done reading Unicode Character Database");
			
			// add algorithmic Hangul decompositions
			// this is more compact if done at runtime, but for simplicity we
			// do it this way.
			
//			if (DEBUG) trace("Adding Hangul");
			
			first = 0;
			second = 0;
			
			for (var SIndex:int = 0; SIndex < SCount; ++SIndex)
			{
				var TIndex:int = SIndex % TCount;
				
				if (TIndex != 0) // triple
				{
					first = (SBase + SIndex - TIndex);
					second = (TBase + TIndex);
				}
				else
				{
					first = (LBase + SIndex / NCount);
					second = (VBase + (SIndex % NCount) / TCount);
				}
				
				pair = (first << 16) | second;
				
				value = SIndex + SBase;
				
				decompose.put(value, String.fromCharCode(first) + second);
				
				compose.put(pair, value);
			}
		}
		
		/**
		 * For use in an applet: just load a minimal set of data.
		 */
		private static function setMinimalDecomp(canonicalClass:IntHashtable, decompose:IntStringHashtable, 
			compose:IntHashtable , isCompatibility:Object, isExcluded:Object):void 
		{
			var decomposeData:Array= 
			[
				"\u005E", "\u0020\u0302", "K",
				"\u005F", "\u0020\u0332", "K",
				"\u0060", "\u0020\u0300", "K",
				"\u00A0", "\u0020", "K",
				"\u00A8", "\u0020\u0308", "K",
				"\u00AA", "\u0061", "K",
				"\u00AF", "\u0020\u0304", "K",
				"\u00B2", "\u0032", "K",
				"\u00B3", "\u0033", "K",
				"\u00B4", "\u0020\u0301", "K",
				"\u00B5", "\u03BC", "K",
				"\u00B8", "\u0020\u0327", "K",
				"\u00B9", "\u0031", "K",
				"\u00BA", "\u006F", "K",
				"\u00BC", "\u0031\u2044\u0034", "K",
				"\u00BD", "\u0031\u2044\u0032", "K",
				"\u00BE", "\u0033\u2044\u0034", "K",
				"\u00C0", "\u0041\u0300", "",
				"\u00C1", "\u0041\u0301", "",
				"\u00C2", "\u0041\u0302", "",
				"\u00C3", "\u0041\u0303", "",
				"\u00C4", "\u0041\u0308", "",
				"\u00C5", "\u0041\u030A", "",
				"\u00C7", "\u0043\u0327", "",
				"\u00C8", "\u0045\u0300", "",
				"\u00C9", "\u0045\u0301", "",
				"\u00CA", "\u0045\u0302", "",
				"\u00CB", "\u0045\u0308", "",
				"\u00CC", "\u0049\u0300", "",
				"\u00CD", "\u0049\u0301", "",
				"\u00CE", "\u0049\u0302", "",
				"\u00CF", "\u0049\u0308", "",
				"\u00D1", "\u004E\u0303", "",
				"\u00D2", "\u004F\u0300", "",
				"\u00D3", "\u004F\u0301", "",
				"\u00D4", "\u004F\u0302", "",
				"\u00D5", "\u004F\u0303", "",
				"\u00D6", "\u004F\u0308", "",
				"\u00D9", "\u0055\u0300", "",
				"\u00DA", "\u0055\u0301", "",
				"\u00DB", "\u0055\u0302", "",
				"\u00DC", "\u0055\u0308", "",
				"\u00DD", "\u0059\u0301", "",
				"\u00E0", "\u0061\u0300", "",
				"\u00E1", "\u0061\u0301", "",
				"\u00E2", "\u0061\u0302", "",
				"\u00E3", "\u0061\u0303", "",
				"\u00E4", "\u0061\u0308", "",
				"\u00E5", "\u0061\u030A", "",
				"\u00E7", "\u0063\u0327", "",
				"\u00E8", "\u0065\u0300", "",
				"\u00E9", "\u0065\u0301", "",
				"\u00EA", "\u0065\u0302", "",
				"\u00EB", "\u0065\u0308", "",
				"\u00EC", "\u0069\u0300", "",
				"\u00ED", "\u0069\u0301", "",
				"\u00EE", "\u0069\u0302", "",
				"\u00EF", "\u0069\u0308", "",
				"\u00F1", "\u006E\u0303", "",
				"\u00F2", "\u006F\u0300", "",
				"\u00F3", "\u006F\u0301", "",
				"\u00F4", "\u006F\u0302", "",
				"\u00F5", "\u006F\u0303", "",
				"\u00F6", "\u006F\u0308", "",
				"\u00F9", "\u0075\u0300", "",
				"\u00FA", "\u0075\u0301", "",
				"\u00FB", "\u0075\u0302", "",
				"\u00FC", "\u0075\u0308", "",
				"\u00FD", "\u0079\u0301", "",
				// EXTRAS, outside of Latin 1
				"\u1EA4", "\u00C2\u0301", "",
				"\u1EA5", "\u00E2\u0301", "",
				"\u1EA6", "\u00C2\u0300", "",
				"\u1EA7", "\u00E2\u0300", "",
			];
			
			var classData:Array = [
				0x0300, 230,
				0x0301, 230,
				0x0302, 230,
				0x0303, 230,
				0x0304, 230,
				0x0305, 230,
				0x0306, 230,
				0x0307, 230,
				0x0308, 230,
				0x0309, 230,
				0x030A, 230,
				0x030B, 230,
				0x030C, 230,
				0x030D, 230,
				0x030E, 230,
				0x030F, 230,
				0x0310, 230,
				0x0311, 230,
				0x0312, 230,
				0x0313, 230,
				0x0314, 230,
				0x0315, 232,
				0x0316, 220,
				0x0317, 220,
				0x0318, 220,
				0x0319, 220,
				0x031A, 232,
				0x031B, 216,
				0x031C, 220,
				0x031D, 220,
				0x031E, 220,
				0x031F, 220,
				0x0320, 220,
				0x0321, 202,
				0x0322, 202,
				0x0323, 220,
				0x0324, 220,
				0x0325, 220,
				0x0326, 220,
				0x0327, 202,
				0x0328, 202,
				0x0329, 220,
				0x032A, 220,
				0x032B, 220,
				0x032C, 220,
				0x032D, 220,
				0x032E, 220,
				0x032F, 220,
				0x0330, 220,
				0x0331, 220,
				0x0332, 220,
				0x0333, 220,
				0x0334, 1,
				0x0335, 1,
				0x0336, 1,
				0x0337, 1,
				0x0338, 1,
				0x0339, 220,
				0x033A, 220,
				0x033B, 220,
				0x033C, 220,
				0x033D, 230,
				0x033E, 230,
				0x033F, 230,
				0x0340, 230,
				0x0341, 230,
				0x0342, 230,
				0x0343, 230,
				0x0344, 230,
				0x0345, 240,
				0x0360, 234,
				0x0361, 234
			];
			
			// build the same tables we would otherwise get from the
			// Unicode Character Database, just with limited data
			
			var i:int;
				
			for (i = 0; i < decomposeData.length; i+=3)
			{
				var value:int = decomposeData[i].charCodeAt(0);
				var decomp:String = decomposeData[i+1];
				var compat:Boolean = decomposeData[i+2] == "K";
				
				if (compat) 
					isCompatibility[value] = true;
				
				decompose.put(value, decomp);
				
				if (!compat)
				{
					var first:int = 0x0000;
					var second:int = decomp.charCodeAt(0);
					
					if (decomp.length > 1)
					{
						first = second;
						second = decomp.charCodeAt(1);
					}
					
					var pair:int = (first << 16) | second;
					
					compose.put(pair, value);
				}
			}
			
			for (i = 0; i < classData.length;)
			{
				canonicalClass.put(classData[i++], classData[i++]);
			}
		}
		
		/**
		 * Utility: Parses a sequence of hex Unicode characters separated by spaces
		 */
		public static function fromHex(source:String):String
		{
			var result:String = "";
			
			for (var i:int = 0; i < source.length; ++i)
			{
				var c:String = source.charAt(i);
				
				switch (c)
				{
					case ' ': 
						break; // ignore
					
					case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': 
					case '8': case '9': case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': 
					case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
						
						result += String.fromCharCode(parseInt(source.substring(i, i + 4), 16));
						i += 3; // skip rest of number
						
						break;
					
					case '<': 
						var j:int = source.indexOf('>', i); // skip <...>
						if (j > 0)
						{
							i = j;
							break;
						} // else fall through--error
						
					default:
						throw new Error("Bad hex value in " + source);
				}
			}
			
			return result;
		}
		
		/**
		 * Utility: Supplies a zero-padded hex representation of an integer (without 0x)
		 */
		public static function hex(i:int):String 
		{
			var result:String = int(i & 0xFFFFFFFF).toFixed(16).toString();
			
			return "00000000".substring(result.length, 8) + result;
		}
		
//		/**
//		 * Utility: Supplies a zero-padded hex representation of a Unicode character (without 0x, \\u)
//		 */
//		static public String hex(char i)
//		{
//			String result = Integer.toString(i, 16).toUpperCase();
//			return "0000".substring(result.length(),4) + result;
//		}
		
//		/**
//		 * Utility: Supplies a zero-padded hex representation of a Unicode character (without 0x, \\u)
//		 */
//		public static String hex(String s, String sep)
//		{
//			StringBuffer result = new StringBuffer();
//			for (int i = 0; i < s.length(); ++i) {
//				if (i != 0) result.append(sep);
//				result.append(hex(s.charAt(i)));
//			}
//			return result.toString();
//		}

	}
}