//
//  Weather.m
//  Horse
//
//  Created by Carlos Santiago on 8/28/16.
//  Copyright 2016 slashlos. All rights reserved.
//
//	Split from Extras.m

#import "Weather.h"

#define	dateComponents	\
	(NSCalendarUnitYear | NSCalendarUnitMonth  | NSCalendarUnitDay | \
NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)

NSInteger RunAlertPanel(
						NSString * title,
						NSString * format,
						NSString * defButton,
						NSString * altButton,
						NSString * othButton)
{
	NSView * contentView = [[NSApp keyWindow] contentView];
	
	//	Before starting the alert panel, ensure we're
	//	not in full screen mode; exit first if we are
	if ([contentView isInFullScreenMode])
	{
		[contentView exitFullScreenModeWithOptions:nil];
	}
#if (TARGET_OS_MAC && (MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5))
	NSAlert * alert = [[NSAlert alloc] init];
	
	[alert setMessageText:title];
	[alert addButtonWithTitle:defButton];
	[alert addButtonWithTitle:altButton];
	[alert addButtonWithTitle:othButton];
	[alert setInformativeText:format];
	
	return [alert runModal];
#else
	return NSRunAlertPanel(title,@"%@",defButton,altButton,othButton,format);
#endif
}

@implementation NSDateFormatter (Extras)
+ (id)withFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:format];
	if (timeZone)
	{
		[dateFormat setTimeZone:timeZone];
	}
	return dateFormat;
}
@end

@implementation NSString (Weather)
- (NSString *)URLEncodedString
{
	NSMutableString * tempStr = [NSMutableString stringWithString:self];
	NSCharacterSet * cs = [NSCharacterSet URLHostAllowedCharacterSet];

	[tempStr replaceOccurrencesOfString:@" "
							 withString:@"+"
								options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, [tempStr length])];

//	return [[NSString stringWithFormat:@"%@",tempStr]
//			stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [[NSString stringWithFormat:@"%@", tempStr]
			stringByAddingPercentEncodingWithAllowedCharacters:cs];
}

+ (NSString *)weatherStringWithContentsOfURL:(NSURL *)weatherURL
{
	NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
	__block NSString * weatherString = nil;
	NSStringEncoding enc=0;

	//	First fetch the weather response text if we can or simulate it

	while (YES)
	{
		NSString * defButton=nil, * altButton=nil, *othButton=nil;
		NSError * err=nil;

		NSURLSession * aSession = [NSURLSession sessionWithConfiguration:config];
		[[aSession dataTaskWithURL:weatherURL completionHandler:
		  ^(NSData *data, NSURLResponse *response, NSError *error)
		  {
			  if (((NSHTTPURLResponse *)response).statusCode == 200)
			  {
				  if (data)
				  {
					  weatherString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				  }
			  }
		  }] resume];

		//	Uh oh, try one more time, syncrhonously, to fetch weather string
		if (!weatherString.length)
		{
			weatherString = [NSString stringWithContentsOfURL:weatherURL usedEncoding:&enc error:&err];
		}
		if (!err && [weatherString length]) break;

		defButton = [[err localizedRecoveryOptions] objectAtIndex:0];
		if (!defButton) defButton = @"OK";
		altButton = [[err localizedRecoveryOptions] objectAtIndex:1];
		if (!altButton) altButton = @"Simulate weather";
		othButton = [[err localizedRecoveryOptions] objectAtIndex:2];
		if (!othButton) othButton = @"Retry";

		switch (RunAlertPanel(
							  @"Error retrieving weather information",
							  [NSString stringWithFormat:
							   @"%@\nReason: %@\nSuggestion: %@",
							   [err localizedDescription],
							   ([err localizedFailureReason] ?
								[err localizedFailureReason] : @"Network unavailable"),
							   ([err localizedRecoverySuggestion] ?
								[err localizedRecoverySuggestion] : @"Retry weather access")],
							  defButton, altButton, othButton))
		{
			case NSAlertFirstButtonReturn:
				return nil;
			case NSAlertSecondButtonReturn:
				return [NSString string];
			case NSAlertThirdButtonReturn:
				;//try it again
		}
	}

	return weatherString;
}
@end

@implementation NSDictionary (Weather)
- (NSURL *)weatherURLBy:(WeatherProvider_t)provider
{
	NSString *urlString=nil, *address=nil;
	
	//	Formulate location based on track information availalble - by preference
	//
	//	owmid			id=open-weather-map-location[id]
	//	city[,cc]		q=city-name[city], country-code[cc]
	//	zip[,cc]		zip=zip-code[zip], country-code[cc]
	//	lat,lon			lat=lattitude[lat], longitude[lon]
	//	woeid			w=where-on-earth-id[woeid]
	//
	NSString * locationArgs = [self locationArgsBy:provider];

	switch (provider)
	{
		case kWeatherByWeatherUnderground:	// Weather Underground
			urlString = @"http://api.wunderground.com/api/%@/conditions/q%@";
			address = [NSString stringWithFormat:urlString, wuAppKey, locationArgs];
			break;

		case kWeatherByOpenWeatherMap:	// Open Weather Map
			urlString = @"http://api.openweathermap.org/data/2.5/weather?%@&appid=%@&mode=xml&units=imperial";
			address = [NSString stringWithFormat:urlString, [locationArgs URLEncodedString], owmAppKey];
			break;

		case kWeatherByYahoo:	// Yahoo weather
		{
			NSString * yql = @"select * from weather.forecast where woeid in (select woeid from geo.places(1) where ";

			//	Use the public API leaving OAuth for another day ...
			urlString = @"https://query.yahooapis.com/v1/public/yql?q=%@%@)%@";

			address = [NSString stringWithFormat:urlString,
					   [yql URLEncodedString],
					   [locationArgs URLEncodedString],
					   @"&format=json"];
			break;
		}

		default:
			NSLog(@"Unknown weather provider(%d), using simulation", provider);
	}

	return [NSURL URLWithString:address];
}

- (NSString *)locationArgsBy:(WeatherProvider_t)provider
{
	NSMutableString * locationArgs = [[NSMutableString alloc] init];

	//	provide query args by provider drawing on location dictionary
	switch (provider)
	{
		case kWeatherByWeatherUnderground:

			[locationArgs appendFormat:@"/%@/%@%@", self[@"st"], self[@"city"], @".xml"];
			[locationArgs replaceOccurrencesOfString:@" " withString:@"_"
											 options:0
											   range:NSMakeRange(0,locationArgs.length)];
			break;

		case kWeatherByOpenWeatherMap:

			//	Return weather argument by order of perference
			if (self[@"id"] || self[@"_id"])
			{
				if (self[@"id"])
					[locationArgs appendFormat:@"id=%@", self[@"id"]];
				else
					[locationArgs appendFormat:@"id=%@", self[@"_id"]];
				if (self[@"cc"])
				{
					[locationArgs appendFormat:@",%@", self[@"cc"]];
				}
			}
			
			if (self[@"lat"] && self[@"lon"])
			{
				[locationArgs appendFormat:@"lat=%@&lon=%@", self[@"lat"], self[@"lon"]];
				break;
			}

			if (self[@"zip"])
			{
				[locationArgs appendFormat:@"zip=%@", self[@"zip"]];
				if (self[@"cc"])
				{
					[locationArgs appendFormat:@",%@", self[@"cc"]];
				}
				break;
			}

			//	We don't have a location id, do table lookup
			if (self[@"city"])
			{
				[locationArgs appendFormat:@"q=\"%@,%@\"", self[@"city"],
				 ([@"us" isEqualToString:self[@"cc"]] ? self[@"st"] : self[@"cc"])];
				break;
			}
			break;

		case kWeatherByYahoo:
			[locationArgs appendFormat:@"text=\"%@,%@\"", self[@"city"],
			 ([self[@"cc"] isEqualToString:@"us"] ? self[@"st"] : self[@"cc"])];
			break;

		case kWeatherBySimulation:
			;
	}

	return locationArgs;
}

#pragma mark Weather Providers

+ (id)weatherByYahoo:(NSURL *)weatherURL
{
	NSString * weatherString = [NSString weatherStringWithContentsOfURL:weatherURL];
	NSMutableDictionary * dict = nil;
	NSError * jsonError = nil;
	NSDictionary * json = nil;

	//	Build our return weather dictionary or use a simulation
	if (weatherString.length)
	{
		NSData * objectData = [weatherString dataUsingEncoding:NSUTF8StringEncoding];

		json = [NSJSONSerialization JSONObjectWithData:objectData
											   options:NSJSONReadingMutableContainers
												 error:&jsonError];
	}
	else
	if (weatherString)
	{
		[dict addEntriesFromDictionary:[NSDictionary weatherBySimulation]];
	}

	//	Something went wrong...
	if (![json count])
	{
		return nil;
	}
	else
	{
		dict = [[NSMutableDictionary alloc] init];
	}

	//	Now, marshall json dictionary into model
	dict[@"astronomy"] = json[@"query"][@"results"][@"channel"][@"astronomy"];
	dict[@"atmosphere"] = json[@"query"][@"results"][@"channel"][@"atmosphere"];
	dict[@"description"] = json[@"query"][@"results"][@"channel"][@"description"];
	dict[@"condition"] = json[@"query"][@"results"][@"channel"][@"item"][@"condition"];
	dict[@"forecast"] = json[@"query"][@"results"][@"channel"][@"item"][@"forecast"][0];// first array entry
	dict[@"image"] = json[@"query"][@"results"][@"channel"][@"image"];
	dict[@"item"] = json[@"query"][@"results"][@"channel"][@"item"];
	dict[@"language"] = json[@"query"][@"results"][@"channel"][@"language"];
	dict[@"lastBuildDate"] = json[@"query"][@"results"][@"channel"][@"lastBuildDate"];
	dict[@"link"] = json[@"query"][@"results"][@"channel"][@"link"];
	dict[@"location"] = json[@"query"][@"results"][@"channel"][@"location"];
	dict[@"title"] = json[@"query"][@"results"][@"channel"][@"title"];
	dict[@"ttl"] = json[@"query"][@"results"][@"channel"][@"ttl"];
	dict[@"units"] = json[@"query"][@"results"][@"channel"][@"units"];
	dict[@"wind"] = json[@"query"][@"results"][@"channel"][@"wind"];

	//	Add our signature
	dict[@"provided"] = @"ByYahoo!";
	dict[@"provider"] = @(kWeatherByYahoo);

	return dict;
}

+ (id)weatherByOpenWeatherMap:(NSURL *)weatherURL
{
	NSString * weatherString = [NSString weatherStringWithContentsOfURL:weatherURL];
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];

	//	Build our return weather dictionary or use a simulation
	if (weatherString.length)
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithXMLString:weatherString]];
	else
	if (weatherString)
	{
		[dict addEntriesFromDictionary:[NSDictionary weatherBySimulation]];
	}

	//	Now add translation maps, fill in missing cells from sims
	NSDictionary * sims = [self weatherBySimulation];
	NSMutableDictionary * temp = nil;

	temp = [NSMutableDictionary dictionary];
	temp[@"sunrise"] = dict[@"city"][@"sun"][@"_rise"];
	temp[@"sunset"] = dict[@"city"][@"sun"][@"_set"];
	dict[@"astronomy"] = temp;
	
	temp = [NSMutableDictionary dictionary];
	temp[@"humidity"] = dict[@"humidity"][@"_value"];
	temp[@"pressure"] = dict[@"pressure"][@"_value"];
	dict[@"atmosphere"] = temp;
	
	temp = [NSMutableDictionary dictionary];
	///	temp[@"code"] = 30;
	temp[@"date"] = dict[@"lastupdate"][@"_value"];
	temp[@"temp"] = dict[@"temperature"][@"_value"];
	temp[@"text"] = dict[@"weather"][@"_value"];
	dict[@"condition"] = temp;
	
	temp = [NSMutableDictionary dictionary];
	temp[@"description"] = dict[@"weather"][@"_value"];
	temp[@"code"] = dict[@"weather"][@"_number"];//todo map this
	temp[@"date"] = sims[@"forecast"][@"date"];
	temp[@"day"] = sims[@"forecast"][@"day"];;
	temp[@"high"] = dict[@"temperature"][@"_max"];
	temp[@"low"] = dict[@"temperature"][@"_min"];
	temp[@"text"] = dict[@"clouds"][@"_name"];
	dict[@"forecast"] = temp;
	
	//	image - none
	dict[@"item"] = dict[@"weather"][@"_value"];
	dict[@"language"] = @"en-us";
	dict[@"lastBuildDate"] = dict[@"lastupdate"][@"_value"];
//	dict[@"link"] - none
	
	temp = [NSMutableDictionary dictionary];
	temp[@"city"] = dict[@"city"][@"_name"];
	temp[@"country"] = dict[@"city"][@"country"];
//	temp[@"region"] - none
	dict[@"location"] = temp;
	
	dict[@"title"] = [NSString stringWithFormat:@"Open Weather Map Weather - %@, %@",
					  dict[@"location"][@"city"],
					  dict[@"location"][@"country"]];
	dict[@"ttl"] = @60;
	dict[@"units"] = sims[@"units"];
	
	temp = [NSMutableDictionary dictionary];
//	temp[@"chill"] - none
	temp[@"direction"] = dict[@"wind"][@"direction"][@"_value"];
	temp[@"speed"] = dict[@"wind"][@"speed"][@"_value"];
	temp[@"code"] = dict[@"wind"][@"direction"][@"_code"];
	temp[@"name"] = dict[@"wind"][@"direction"][@"_name"];
	dict[@"wind"] = temp;

	//	Add our signature
	dict[@"provided"] = @"ByOpenWeatherMap";
	dict[@"provider"] = @(kWeatherByOpenWeatherMap);

	return dict;
}

+ (id)weatherByWeatherUnderground:(NSURL *)weatherURL
{
	NSString * weatherString = [NSString weatherStringWithContentsOfURL:weatherURL];
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];

	//	Build our return weather dictionary or use a simulation
	if (weatherString.length)
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithXMLString:weatherString]];
	else
	if (weatherString)
	{
		[dict addEntriesFromDictionary:[NSDictionary weatherBySimulation]];
	}

	//	Build our return weather dictionary
	[dict addEntriesFromDictionary:[NSDictionary dictionaryWithXMLString:weatherString]];

	//	Something went wrong...
	if (![dict count])
	{
		return nil;
	}

	//	Now add translation maps, fill in missing cells from sims
	NSDictionary * sims = [self weatherBySimulation];
	NSMutableDictionary * temp = nil;

	dict[@"astronomy"] = sims[@"astronomy"];

	temp = [NSMutableDictionary dictionary];
	temp[@"humidity"] = dict[@"current_observation"][@"relative_humidity"];
	temp[@"pressure"] = dict[@"current_observation"][@"pressure_in"];
	temp[@"rising"]	= dict[@"current_observation"][@"pressure_trend"];
	temp[@"visibility"] = dict[@"current_observation"][@"visibility_mi"];
	dict[@"atmosphere"] = temp;

	temp = [NSMutableDictionary dictionary];
///	temp[@"code"] = 30;
	temp[@"date"] = dict[@"current_observation"][@"observation_time"];
	temp[@"temp"] = dict[@"current_observation"][@"temp_f"];
	temp[@"text"] = dict[@"current_observation"][@"weather"];
	dict[@"condition"] = temp;

	temp = [NSMutableDictionary dictionary];
	temp[@"description"] = dict[@"current_observation"][@"image"][@"title"];
///	temp[@"code"] = 30;
	temp[@"date"] = sims[@"forecast"][@"date"];
	temp[@"day"] = sims[@"forecast"][@"day"];;
	temp[@"high"] = dict[@"current_observation"][@"windchill_f"];
	temp[@"low"] = dict[@"current_observation"][@"windchill_f"];
	temp[@"text"] = dict[@"current_observation"][@"weather"];
	dict[@"forecast"] = temp;

//	image - already set
	dict[@"item"] = dict[@"current_observation"][@"observation_time"];
	dict[@"language"] = @"en-us";
	dict[@"lastBuildDate"] = dict[@"current_observation"][@"observation_time"];
	dict[@"link"] = dict[@"current_observation"][@"ob_url"];

	temp = [NSMutableDictionary dictionary];
	temp[@"city"] = dict[@"current_observation"][@"city"];
	temp[@"country"] = dict[@"current_observation"][@"country"];
	temp[@"region"] = dict[@"current_observation"][@"state_name"];
	dict[@"location"] = temp;

	dict[@"title"] = dict[@"current_observation"][@"image"][@"title"];
	dict[@"ttl"] = @60;
	dict[@"units"] = sims[@"units"];

	temp = [NSMutableDictionary dictionary];
	temp[@"chill"] = dict[@"current_observation"][@"windchill_f"];
	temp[@"direction"] = dict[@"current_observation"][@"wind_degrees"];
	temp[@"speed"] = dict[@"current_observation"][@"wind_mph"];
	dict[@"wind"] = temp;

	//	Add our signature
	dict[@"provided"] = @"ByWeatherUnderground";
	dict[@"provider"] = @(kWeatherByWeatherUnderground);

	return dict;
}

+ (id)weatherBySimulation
{
	NSCalendar * gregorian = [[NSCalendar alloc]
							  initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init], * vals;
	NSTimeZone * timeZone = [NSTimeZone defaultTimeZone];
	NSDateFormatter * timeFormat =
		[NSDateFormatter withFormat:@"h:mm a z" timeZone:timeZone];
	NSDateFormatter * dateFormat =
		[NSDateFormatter withFormat:@"d MMM YYYY" timeZone:timeZone];
	NSDateFormatter * dateFormat2 =
		[NSDateFormatter withFormat:@"EEE, d MMM YYYY h:mm a z" timeZone:timeZone];
	NSDateFormatter * dateFormat3 =
		[NSDateFormatter withFormat:@"EEE" timeZone:timeZone];
	NSDateComponents * theDate = [[NSCalendar currentCalendar]
		components:dateComponents fromDate:[NSDate date]];
	NSString * localizedName = [[NSHost currentHost] localizedName];
	NSString * val;
	NSInteger temp;

	//	Firstly, mark that we're a simulation
	[dict setObject:@"1" forKey:@"simulation"];

	//
	//	'astronomy' dictionary of values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"astronomy"];

	[theDate setHour:4+Random(2)];
	[theDate setMinute:Random(60)];
	[theDate setSecond:Random(60)];
	[theDate setTimeZone:timeZone];

	val = [timeFormat stringFromDate:[gregorian dateFromComponents:theDate]];
	[vals setObject:val forKey:@"sunrise"];

	[theDate setHour:16+Random(2)];
	[theDate setMinute:Random(60)];
	[theDate setSecond:Random(60)];

	val = [timeFormat stringFromDate:[gregorian dateFromComponents:theDate]];
	[vals setObject:val forKey:@"sunset"];

	//
	//	'wind' dictionary of values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"wind"];

	temp = 32 + Random(64);
	[vals setObject:[NSString stringWithFormat:@"%ld", temp - Random(10)] forKey:@"chill"];
	[vals setObject:[NSString stringWithFormat:@"%ld", Random(360)] forKey:@"direction"];
	[vals setObject:[NSString stringWithFormat:@"%ld", Random(25)] forKey:@"speed"];

	//
	//	miscellaneous values
	//

	[dict setObject:@"https://l.yimg.com/a/i/us/nws/th/main_142b.gif" forKey:@"image"];
	[dict setObject:@"60" forKey:@"ttl"];
	val = [NSString stringWithFormat:@"Conditions for %@, at %@",
		localizedName,
		[timeFormat stringFromDate:[NSDate date]] ];
	[dict setObject:val forKey:@"item"];

	val = [dateFormat2 stringFromDate:[NSDate date]];
	[dict setObject:val forKey:@"lastBuildDate"];

	val = [NSString stringWithFormat:@"Yahoo! Weather for %@",localizedName];
	[dict setObject:val forKey:@"description"];
	[dict setObject:@"https://weather.yahoo.com/forecast/USNY0464_f.html" forKey:@"link"];
	val = [NSString stringWithFormat:@"Yahoo! Weather - %@, Internet",localizedName];
	[dict setObject:val forKey:@"title"];
	[dict setObject:@"en-us" forKey:@"language"];

	//
	//	'forecast' values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"forecast"];

	[vals setObject:@"30" forKey:@"code"];

	val = [dateFormat stringFromDate:[NSDate date]];
	[vals setObject:val forKey:@"date"];

	val = [dateFormat3 stringFromDate:[NSDate date]];
	[vals setObject:val forKey:@"day"];

	[vals setObject:[NSString stringWithFormat:@"%ld", temp - Random(10)] forKey:@"low"];
	[vals setObject:[NSString stringWithFormat:@"%ld", temp + Random(10)] forKey:@"high"];
	[vals setObject:@"Partly Cloudy" forKey:@"text"];

	//
	//	'atmosphere' values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"atmosphere"];

	[vals setObject:@"46" forKey:@"humidity"];
	[vals setObject:@"30.24" forKey:@"pressure"];
	[vals setObject:@"2" forKey:@"rising"];
	[vals setObject:@"10" forKey:@"visibility"];

	//
	//	'location' values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"location"];

	[vals setObject:@"hedwig.local" forKey:@"city"];
	[vals setObject:@"Internet" forKey:@"country"];
	[vals setObject:@"Americas" forKey:@"region"];

	//
	//	'condition' values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"condition"];

	[vals setObject:@"30" forKey:@"code"];
	val = [dateFormat2 stringFromDate:[NSDate date]];
	[vals setObject:val forKey:@"date"];
	[vals setObject:[NSString stringWithFormat:@"%ld", temp] forKey:@"temp"];
	[vals setObject:@"Partly Cloudy" forKey:@"text"];

	//
	//	'units' values
	//

	vals = [NSMutableDictionary dictionary];
	[dict setObject:vals forKey:@"units"];

	[vals setObject:@"mi" forKey:@"distance"];
	[vals setObject:@"in" forKey:@"pressure"];
	[vals setObject:@"mph" forKey:@"speed"];
	[vals setObject:@"F" forKey:@"temperature"];

	dict[@"provided"] = @"BySimulation";
	dict[@"provider"] = @(kWeatherBySimulation);

	return dict;
}

#pragma mark Track Weather

- (id)weatherForBy:(WeatherProvider_t)provider
{
	//	Formulate location based on track information availalble - by preference
	//
	//	owmid			id=open-weather-map-location[id]
	//	city[,cc]		q=city-name[city], country-code[cc]
	//	zip[,cc]		zip=zip-code[zip], country-code[cc]
	//	lat,lon			lat=lattitude[lat], longitude[lon]
	//	woeid			w=where-on-earth-id[woeid]
	//
	NSURL * weatherURL = [self weatherURLBy:provider];
	NSDictionary * weather = nil;

	switch (provider)
	{
		case kWeatherByYahoo:
			weather = [NSDictionary weatherByYahoo:weatherURL];
			break;

		case kWeatherByOpenWeatherMap:
			weather = [NSDictionary weatherByOpenWeatherMap:weatherURL];
			break;

		case kWeatherByWeatherUnderground:
			weather = [NSDictionary weatherByWeatherUnderground:weatherURL];
			break;

		default:
			NSLog(@"Unknown weather provider(%d), using simulation", provider);

		case kWeatherBySimulation:
			weather = [NSDictionary weatherBySimulation];
	}

	//	If anything went wrong, simulate the weather
	if (weather.count)
		return weather;
	else
	{
		if (weather)
		{
			NSLog(@"Error retrieving from provider (%d", provider);
		}
		return [NSDictionary weatherBySimulation];
	}

	return nil;
}
@end
