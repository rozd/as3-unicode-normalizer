normalizer
==========

Implementation of Unicode Normalization, supports four normalization forms: NFD, NFC, NFKD, NFKC

Usage
-------

Import and instantiate `Normalizer()` class 
use it's `Normalizer.normalize(NormalizationForm, FullData)` method, where Normalization

The `Normalizer(form, fullData)` constructor takes two params. First `form` param specifies 
one of four normalization from enumeration [Normalizer.C, Normalizer.D, Normalizer.FC, Normalizer.KD]. 
Second param `fullData` is a flag that specified whether extended tables will be used.

Sample
-------

In the next example Normalization used for decomposing ligature during comparing srtings:

	const nfkd:Normalizer = new Normalizer(Normalizer.KD, true);
  			
	trace("ﬂ" == "fl"); // false
	
	trace (nfkd.normalize("ﬂ") == nfkd.normalize("fl")) // true
  
  
