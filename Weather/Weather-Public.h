//
//  Weather-Public.h
//  Weather
//
//  Created by Carlos Santiago on 10/22/16.
//  Copyright © 2016 Carlos D. Santiago. All rights reserved.
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
#import <XMLDictionary/XMLDictionary.h>
#import <CoreLocation/CoreLocation.h>

//	Fetch globals from preferences
#ifndef	GBLBIN
#define	GBLBIN(x)	[[NSUserDefaults standardUserDefaults] boolForKey:(x)]
#endif

#ifndef GBLSTR
#define	GBLSTR(x)	[[NSUserDefaults standardUserDefaults] stringForKey:(x)]
#define	SETSTR(x,v)	[[NSUserDefaults standardUserDefaults] setObject:(v) forKey:(x)]
#endif

#ifndef Random
#define	Random(n)		((n) ? (ABS(random()) % (n)) : 0)
#endif

//	Weather based on HorseWeatherProvider id
typedef enum WeatherProvider
{
	kWeatherBySimulation = 0,
	kWeatherByYahoo,
	kWeatherByOpenWeatherMap,
	kWeatherByWeatherUnderground,
	kWeatherByWeather_com = 10,
	kWeatherByIntellicast,
	kWeatherByForecast_gov
} WeatherProvider_t;

NSInteger RunAlertPanel(NSString * title,
						NSString * format,
						NSString * defButton,
						NSString * altButton,
						NSString * othButton);

@interface NSDateFormatter (Weather)
+ (id)withFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone;
@end

@interface NSString (Weather)
- (NSString *)URLEncodedString;
+ (NSString *)weatherStringWithContentsOfURL:(NSURL *)weatherURL;
@end

@interface NSDictionary (Weather)
- (NSURL *)weatherURLBy:(WeatherProvider_t)provider;
- (NSString *)locationArgsBy:(WeatherProvider_t)provider;
- (void)saveLocationOfCity:(NSMutableDictionary *)city;

+ (id)weatherByYahoo:(NSURL *)address;
+ (id)weatherByOpenWeatherMap:(NSURL *)address;
+ (id)weatherByWeatherUnderground:(NSURL *)address;

- (id)weatherBy:(WeatherProvider_t)provider;
+ (id)weatherBySimulation;
@end
