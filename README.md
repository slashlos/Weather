Purpose
--------------

Weather is a series of methods to simplify weather collection to a
dictionary to single model.  Supporting various weather providers,
an attempt is make to unify the results to a single standard.

The caller passes in a dictionary containing a few args such as

	lat, lot	latitude, longitude
	cc			country code
	st			state code
	loc			location code - weather.com, yahoo!
	wooed		where on Earth id
	owmid		open weather map location id

which are used in the formation of a weather URL which is read, parsed
and returnd as a dictionary.  The caller in addition to the location
dictionary, passes in the provider type - see Weather header for the
dictionary model returned.


Setup
-------

To use the Weather in an app, just drag the class files into your project and 
edit the Weather header to instrument your app keys and id codes.

The use of individual weather providers require registration of authentication keys.

See

    Yahoo!					https://developer.yahoo.com/weather/ (currently NYI, public api used)
	Open Weather Map		http://openweathermap.org/api
	Weather Underground		https://www.wunderground.com/

In all cases, weather results are unified into a consistent weather results when possible.
(i.e., most provides do not provide astrology info)


ARC Compatibility
------------------

As of version 0.1, Weather is non-ARC.


Weather Category Methods
--------------------------

Weather extends NSString and NSDictionary with the following methods:


NSString
----------

- (NSString *)URLEncodedString

Address illegal URL characters in string

+ (NSString *)weatherStringWithContentsOfURL:(NSURL *)weatherURL;

Read URL into a string - synchronous currently


NSDictionary
--------------------------

- (NSURL *)weatherURLBy:(WeatherProvider_t)provider

Return URL by provider using a location dictionary

- (NSString *)locationArgsBy:(WeatherProvider_t)provider

Formulate location args using a location dictionary

+ (id)weatherByYahoo:(NSURL *)address

Return weather provided by Yahoo!

+ (id)weatherByOpenWeatherMap:(NSURL *)address

Return weather provided by Open Weather Map

+ (id)weatherByWeatherUnderground:(NSURL *)address

Return weather provided by Weather Underground

- (id)weatherForBy:(WeatherProvider_t)provider

Return weather provider by provider indicated

+ (id)weatherBySimulation

Return a weather model simulation to which all provider results are normalized against:


XMLDictionary Framework
-------------------------

Weather makes use of the XMLDictionary Framework package found also on github:

	https://github.com/danielctull-forks/XMLDictionary-Framework

    
Release Notes
----------------

Version 0.1

- Initial release

/los
