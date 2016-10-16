//
//  Weather.h
//  Horse
//
//  Created by Carlos Santiago on 8/28/16.
//  Copyright 2016 slashlos. All rights reserved.
//
//	Split from Extras.h
//
//	JSON, XML parsing by
//
//		https://github.com/danielctull-forks/XMLDictionary-Framework
//		https://github.com/nicklockwood/XMLDictionary
//
//	Dictionary model / simulation
//
//  {
//    astronomy = { sunrise, sunset }
//    atmosphere = { humidity, pressure, rising, visibility }
//    condition = { code, date, temp, text }
//    description 
//    forecast = { code, date, day, high, low, text }
//    image
//    item
//    language
//    lastBuildDate
//    link
//    location = { city, country, region }
//    provided
//    provider
//    simulation
//    title
//    ttl
//    units = { distance, pressure, speed, mph, temperature }
//    wind = { chill, direction, speed }
//  }
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

//	Fetch globals from preferences
#ifndef	GBLBIN
#define	GBLBIN(x)	[[NSUserDefaults standardUserDefaults] boolForKey:(x)]
#endif

//	Weather based on HorseWeatherProvider id
typedef enum WeatherProvider
{
	kWeatherBySimulation = 0,
	kWeatherByYahoo,
	kWeatherByOpenWeatherMap,
	kWeatherByWeatherUnderground
} WeatherProvider_t;

//	Yahoo YDL API Keys - public api currentlty used
static const NSString *ydnDefaultKey = @"your-Yahoo!-default key";// currently NYI
static const NSString *ydnSecretKey = @"your-Yahoo!-developer-id";// currently NYI

//	Open Weather Map API Key
static const NSString *owmDefaultKey = @"your-open-weather-map-api-key";
static const NSString *owmAppKey = @"your-open-weather-map-applic-key";

//	Wunderground API key
static const NSString *wuAppKey = @"your-weather-underground-api-key";

@interface NSString (Weather)
- (NSString *)URLEncodedString;
+ (NSString *)weatherStringWithContentsOfURL:(NSURL *)weatherURL;
@end

@interface NSDictionary (Weather)
- (NSURL *)weatherURLBy:(WeatherProvider_t)provider;
- (NSString *)locationArgsBy:(WeatherProvider_t)provider;

+ (id)weatherByYahoo:(NSURL *)address;
+ (id)weatherByOpenWeatherMap:(NSURL *)address;
+ (id)weatherByWeatherUnderground:(NSURL *)address;

- (id)weatherForBy:(WeatherProvider_t)provider;
+ (id)weatherBySimulation;
@end
