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

package org.log5f.unicode.normalization.utils
{
	/**
	 * Contains utility methods to work with <code>String</code> objects.
	 */
	public class StringUtil
	{
		/**
		 * Combines unique symbols from specified string into one and returns it.
		 * 
		 * @param string1 First string to combining 
		 * @param string2 Second string to combining
		 * 
		 * @retuen Combined string
		 */
		public static function combine(string1:String, string2:String):String
		{
			if (!string1) return string2;
			
			if (!string2) return string1;
			
			var result:Array = string1.split("");
			
			for each (var s:String in string2.split(""))
			{
				if (result.indexOf(s) == -1)
					result.push(s);
			}
			
			return result.join("");
		}
	}
}