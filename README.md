Purpose
--------------

Weather is a series of methods to simplify weather collection to a
single model as dictionary.  Supporting various weather providers,
an attempt is make to unify the results to a single standard.  See
method +weatherBySimulation, for the details of the weather model.

The caller passes in a dictionary containing a few args such as

	lat, lot	latitude, longitude
	cc			country code
	st			state code
	loc			location code - weather.com, yahoo!
	wooed		where on Earth id
	owmid		open weather map location id

which are used in the formation of a weather URL which is read, parsed
and returned as a dictionary.  This is known as the "location" dictionary.
From this, various provider routines will choose which argument are required.
The caller in addition to the location dictionary, passes in the provider type;
see Weather public header for the dictionary model returned.


Setup
-------

To use the Weather in an app,

    1. drag the Weather project into your project 
    2. supersede weather keys defined in Weather-Private with your own such as in your  applicationDidFinishLaunching: or similar method, do something like

	//	Load our weather keys
	SETSTR(@"ydnDefKey",@"your-private-key");
	SETSTR(@"ydnAppKey",@"your-private-key");

	//	Open Weather Map API Key
	SETSTR(@"owmDefKey",@"your-private-key");
	SETSTR(@"owmAppKey",@"your-private-key");

	//	WeatherUnderground API key
	SETSTR(@"wuAppKey",@"your-private-key");

Note that the use of individual weather providers require registration of authentication keys.

See

    Yahoo!					https://developer.yahoo.com/weather/ (currently NYI, public api used)
	Open Weather Map		http://openweathermap.org/api
	Weather Underground		https://www.wunderground.com/

In all cases, weather results are unified into a consistent weather results when possible.
(i.e., most provides do not provide astrology info)


ARC Compatibility
------------------

As of version 0.2, Weather is ARC compliant.


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
Version 0.3

- Added weather model and mapping from distinct providers; first pass at using a Soundex Package available at Github Gist: https://gist.github.com/darkseed/1261842, to map weather text strings across providers.

Version 0.2

- Initial release

/los
