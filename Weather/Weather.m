//
//  Weather.m
//  Weather
//
//  Created by Carlos Santiago on 8/28/16.
//  Copyright © 2016 Carlos D. Santiago. All rights reserved.
//
//	Split from Extras.m

#import "Weather.h"

#define	dateComponents	\
	(NSCalendarUnitYear | NSCalendarUnitMonth  | NSCalendarUnitDay | \
NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)

//	Weather model index; measure weather deterioration
static const NSString * wCode = @"code";
static const NSString * wRank = @"rank";
static const NSString * wText = @"text";

#define	kYahooCondSize	48
static struct
{
	NSUInteger rank;
	const char * text;
}
YahooCondCodes[kYahooCondSize] =
{	// index corresponds to weather conditions.code
	{ 10, "tornado" },
	{ 10, "tropical storm" },
	{ 10, "hurricane" },
	{ 10, "severe thunderstorms" },
	{ 10, "thunderstorms" },
	{  9, "mixed rain and snow" },
	{  9, "mixed rain and sleet" },
	{  9, "mixed snow and sleet" },
	{  9, "freezing drizzle" },
	{  8, "drizzle" },
	{  8, "freezing rain" },
	{  8, "showers" },
	{  8, "showers" },
	{  8, "snow flurries" },
	{  7, "light snow showers" },
	{  7, "blowing snow" },
	{  7, "snow" },
	{  8, "hail" },
	{  8, "sleet" },
	{  6, "dust" },
	{  6, "foggy" },
	{  6, "haze" },
	{  4, "smoky" },
	{  4, "blustery" },
	{  2, "windy" },
	{  9, "cold" },
	{  2, "cloudy" },
	{  2, "mostly cloudy (night)" },
	{  2, "mostly cloudy (day)" },
	{  2, "partly cloudy (night)" },
	{  2, "partly cloudy (day)" },
	{  5, "clear (night)" },
	{  1, "sunny" },
	{  4, "fair (night)" },
	{  4, "fair (day)" },
	{  8, "mixed rain and hail" },
	{ 10, "hot" },
	{  9, "isolated thunderstorms" },
	{  8, "scattered thunderstorms" },
	{  8, "scattered thunderstorms" },
	{  8, "scattered showers" },
	{  9, "heavy snow" },
	{  9, "scattered snow showers" },
	{ 11, "heavy snow" },
	{  4, "partly cloudy" },
	{  6, "thundershowers" },
	{  8, "snow showers" },
	{  7, "isolated thundershowers" }
};

#define	kOpenWeatherMapCondSize	73
static struct
{
	NSUInteger code;
	const char * text;
	NSUInteger rank;
}
OpenWeatherMapCondCodes[kOpenWeatherMapCondSize] =
{
// Group 2xx: Thunderstorm
	{ 200,"thunderstorm with light rain",10, },
	{ 201,"thunderstorm with rain",10, },
	{ 202,"thunderstorm with heavy rain",10, },
	{ 210,"light thunderstorm",10, },
	{ 211,"thunderstorm",10, },
	{ 212,"heavy thunderstorm",10, },
	{ 221,"ragged thunderstorm",10, },
	{ 230,"thunderstorm with light drizzle",10, },
	{ 231,"thunderstorm with drizzle",10, },
	{ 232,"thunderstorm with heavy drizzle",10, },
// Group 3xx: Drizzle
	{ 300,"light intensity drizzle",6, },
	{ 301,"drizzle",6, },
	{ 302,"heavy intensity drizzle",6, },
	{ 310,"light intensity drizzle rain",6, },
	{ 311,"drizzle rain",6, },
	{ 312,"heavy intensity drizzle rain",6, },
	{ 313,"shower rain and drizzle",6, },
	{ 314,"heavy shower rain and drizzle",6, },
	{ 321,"shower drizzle",6, },
// Group 5xx: Rain
	{ 500,"light rain",6, },
	{ 501,"moderate rain",6, },
	{ 502,"heavy intensity rain",7, },
	{ 503,"very heavy rain",7, },
	{ 504,"extreme rain",7, },
	{ 511,"freezing rain",8, },
	{ 520,"light intensity shower rain",8, },
	{ 521,"shower rain",8, },
	{ 522,"heavy intensity shower rain",8, },
	{ 531,"ragged shower rain",8, },
// Group 6xx: Snow
	{ 600,"light snow",7, },
	{ 601,"snow",7, },
	{ 602,"heavy snow",7, },
	{ 611,"sleet",7, },
	{ 612,"shower sleet",7, },
	{ 615,"light rain and snow",8, },
	{ 616,"rain and snow",8, },
	{ 620,"light shower snow",8, },
	{ 621,"shower snow",8, },
	{ 622,"heavy shower snow",9, },
// Group 7xx: Atmosphere
	{ 701,"mist",1, },
	{ 711,"smoke",1, },
	{ 721,"haze",1, },
	{ 731,"sand; dust whirls",1, },
	{ 741,"fog",1, },
	{ 751,"sand",1, },
	{ 761,"dust",1, },
	{ 762,"volcanic ash",10, },
	{ 771,"squalls",10, },
	{ 781,"tornado",10, },
// Group 800: Clear
	{ 800,"clear sky",1, },
// Group 80x: Clouds
	{ 801,"few clouds",0, },
	{ 802,"scattered clouds",0, },
	{ 803,"broken clouds",0, },
	{ 804,"overcast clouds",0, },
// Group 90x: Extreme
	{ 900,"tornado",10, },
	{ 901,"tropical storm",10, },
	{ 902,"hurricane",10, },
	{ 903,"cold",8, },
	{ 904,"hot",9, },
	{ 905,"windy",9, },
	{ 906,"hail",10, },
// Group 9xx: Additional
	{ 951,"calm",0, },
	{ 952,"light breeze",1, },
	{ 953,"gentle breeze",1, },
	{ 954,"moderate breeze",1, },
	{ 955,"fresh breeze",1, },
	{ 956,"strong breeze",4, },
	{ 957,"high wind; near gale",4, },
	{ 958,"gale",5, },
	{ 959,"severe gale",5, },
	{ 960,"storm",8, },
	{ 961,"violent storm",9, },
	{ 962,"hurricane",10, }
};

@implementation Weather
+ (NSDictionary *)ydlcodes
{
	static NSDictionary * ydlcodes = nil;

	if (!ydlcodes)
	{
		NSMutableDictionary * ydl = [NSMutableDictionary dictionary];

		//	Mapping codes by key code and text
		for (NSUInteger wthr=0; wthr<kYahooCondSize; wthr++)
		{
			NSString * text = [NSString stringWithFormat:@"%s",YahooCondCodes[wthr].text];
			NSNumber * code = @(wthr);

			ydl[wCode] = @{ wRank : @(YahooCondCodes[wthr].rank),
							wText : text
						  };

			ydl[wText] = @{ wRank : @(YahooCondCodes[wthr].rank),
							wCode : code
						  };
		}

		ydlcodes = ydl;
	}

	return ydlcodes;
}

+ (NSDictionary *)owmcodes
{
	static NSDictionary * owmcodes = nil;

	if (!owmcodes)
	{
		NSMutableDictionary * owm = [NSMutableDictionary dictionary];

		//	Mapping codes by key code and text
		for (NSUInteger owmx=0; owmx<kOpenWeatherMapCondSize; owmx++)
		{
			NSNumber * code = @(OpenWeatherMapCondCodes[owmx].code);
			NSString * text = [NSString stringWithFormat:@"%s",OpenWeatherMapCondCodes[owmx].text];
			NSNumber * rank = @(OpenWeatherMapCondCodes[owmx].rank);

			owm[wCode] = @{ wRank : rank,
							wText : text
						 };

			owm[wText] = @{ wRank : code,
							wText : text
						 };
		}

		owmcodes = owm;
	}
	return owmcodes;
}
@end

#pragma mark Weather Mapping Functions

NSUInteger getRankFromYahooCondCode( NSUInteger condCode )
{
	NSDictionary * ydl = [Weather ydlcodes];
	NSNumber * code = @(condCode);
	
	return [ydl[code][wRank] integerValue];
}

NSString * getTextFromYahooCondCode( NSUInteger condCode )
{
	NSDictionary * ydl = [Weather ydlcodes];
	NSNumber * code = @(condCode);
	
	return ydl[code][wText];
}

NSUInteger getRankFromOWMCondCode( NSUInteger condCode )
{
	NSDictionary * owm = [Weather owmcodes];
	NSNumber * code = @(condCode);
	
	return [owm[code][wRank] integerValue];
}

NSString * getTextFromOWMCondCode( NSUInteger condCode )
{
	NSDictionary * owm = [Weather owmcodes];
	NSNumber * code = @(condCode);
	
	return owm[code][wText];
}

NSDictionary * getModelForWeatherText( NSString * weather )
{
	NSDictionary * ydl = [Weather ydlcodes];

	//	Return first matching entry on text; try small yahoo first
	for (NSNumber * key in ydl.allKeys)
	{
//		if ([ydl[key][wText] rangeOfString:weather
//										  options:NSCaseInsensitiveSearch].location != NSNotFound)
		if ([ydl[key][wText] soundsLikeString:weather])
		{
			NSMutableDictionary * val = [[NSMutableDictionary alloc] initWithDictionary:ydl[key]];

			//	make value complete with its referencing key code and return
			val[wCode] = key;
			return val;
		}
	}

	//	Ok, open weather map next
	for (NSNumber * key in ydl.allKeys)
	{
		if ([ydl[key][wText] soundsLikeString:weather])
		{
			NSMutableDictionary * val = [[NSMutableDictionary alloc] initWithDictionary:ydl[key]];
			
			//	make value complete with its referencing key code and return
			val[wCode] = key;
			return val;
		}
	}

	//	Yoink
	return nil;
}

#pragma mark Utilities

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

@implementation NSDateFormatter (Weather)
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
	//	http://stackoverflow.com/questions/5839877/nsurl-urlwithstringmystring-returns-nil/5839925#5839925

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
		case kWeatherByForecast_gov:
			urlString = @"http://forecast.weather.gov/MapClick.php?%@";
			address = [NSString stringWithFormat:urlString, locationArgs];
			break;

		case kWeatherByIntellicast:
			urlString = @"http://www.intellicast.com/Local/Weather.aspx?location=%@";
			address = [NSString stringWithFormat:urlString, locationArgs];
			break;

		case kWeatherByWeather_com:
			urlString = @"https://weather.com/weather/today/l/%@";
			address = [NSString stringWithFormat:urlString, locationArgs];
			break;

		case kWeatherByWeatherUnderground:	// Weather Underground
			if (!wuAppKey) wuAppKey = GBLSTR(@"wuAppKey");
			urlString = @"http://api.wunderground.com/api/%@/conditions/q%@";
			address = [NSString stringWithFormat:urlString, wuAppKey, locationArgs];
			break;

		case kWeatherByOpenWeatherMap:	// Open Weather Map
			if (!owmDefKey) owmDefKey = GBLSTR(@"owmDefKey");
			if (!owmAppKey) owmAppKey = GBLSTR(@"owmAppKey");
			urlString = @"http://api.openweathermap.org/data/2.5/weather?%@&appid=%@&mode=xml&units=imperial";
			address = [NSString stringWithFormat:urlString, [locationArgs URLEncodedString], owmAppKey];
			break;

		case kWeatherByYahoo:	// Yahoo weather
		{
			NSString * yql = @"select * from weather.forecast where woeid in (select woeid from geo.places(1) where ";
//	 NYI
//	 NYI	if (!ydnDefKey) ydnDefKey = GBLSTR(@"ydnDefKey");	// your Yahoo! default api key - currently NYI
//	 NYI	if (!ydnAppKey) ydnAppKey = GBLSTR(@"ydnAppKey");	// your Yahoo! application key - currently NYI
//	 NYI
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

		case kWeatherBySimulation:
			urlString = @"https://weather.com/weather/today/l/%@";
			address = [NSString stringWithFormat:urlString, locationArgs];
	}

	return [NSURL URLWithString:address];
}

- (NSString *)locationArgsBy:(WeatherProvider_t)provider
{
	NSMutableString * locationArgs = [[NSMutableString alloc] init];

	//	provide query args by provider drawing on location dictionary
	switch (provider)
	{
		case kWeatherByForecast_gov:
			[locationArgs appendFormat:@"lat=%@&lon=%@", self[@"lat"], self[@"lon"]];
			break;

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
				break;
			}

			if (self[@"lat"] && self[@"lon"])
			{
				[locationArgs appendFormat:@"lat=%@&lon=%@", self[@"lat"], self[@"lon"]];
				break;
			}

			if (self[@"zip"] && self[@"cc"])
			{
				[locationArgs appendFormat:@"zip=%@,%@", self[@"zip"], self[@"cc"]];
				break;
			}

			//	We don't have a location id, do city,cc lookup
			if (self[@"city"] && self[@"cc"])
			{
				[locationArgs appendFormat:@"q=\"%@,%@\"", self[@"city"], self[@"cc"]];
				break;
			}
			break;

		case kWeatherByYahoo:
			[locationArgs appendFormat:@"text=\"%@,%@\"", self[@"city"],
			 ([self[@"cc"] isEqualToString:@"us"] ? self[@"st"] : self[@"cc"])];
			break;

		default:
			NSLog(@"Unknown weather provider(%d), using Weather.com", provider);

		case kWeatherByIntellicast:
		case kWeatherByWeather_com:

		case kWeatherBySimulation:
			[locationArgs appendString:self[@"loc"]];
	}

	return locationArgs;
}

- (void)saveLocationOfCity:(NSMutableDictionary *)city
{
	CLGeocoder * geocoder = [[CLGeocoder alloc] init];
	CLLocationDegrees lat = [self[@"coord"][@"lat"] doubleValue];
	CLLocationDegrees lon = [self[@"coord"][@"lon"] doubleValue];
	CLLocation * location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];

	__block NSMutableDictionary * weakCity = city;

	[geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
	 {
		 if (error)
		 {
			 [NSApp presentError:error];
		 }
		 else
		 if (!placemarks.count)
		 {
			 NSLog(@"city %@ not found?", [city description]);
		 }
		 else
		 if (placemarks.count > 1)
		 {
			 //	We already match on city name but filter using state and country code
			 NSPredicate * predicate = [NSPredicate predicateWithFormat:
										@"(administrativeArea like[c] %@) and (ISOcountryCode =[c] %@)",
										weakCity[@"st"], weakCity[@"cc"]];

			 //	When we find a unique city and state and still need lat,log, save it
			 placemarks = [placemarks filteredArrayUsingPredicate:predicate];
		 }

		 //	So save the city coord matching on state and country code
		 for (CLPlacemark * placemark in placemarks)
		 {
			 if (!weakCity[@"lat"] && !weakCity[@"lon"])
			 {
				 // We mamtch on city and state, so capture its coordinates
				 weakCity[@"lat"] = @(placemark.location.coordinate.latitude);
				 weakCity[@"lon"] = @(placemark.location.coordinate.longitude);
			 }
		 }
	 }];
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

	//	insert weather code to index rank mapping
	dict[@"condition"][@"rank"] = @(getRankFromYahooCondCode([dict[@"condition"][@"code"] intValue]));

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

	//	Unify all dates to the model format from UTC format
	NSTimeZone * utcZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSDateFormatter * utc_format = [NSDateFormatter withFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'" timeZone:utcZone];

	NSTimeZone * timeZone = [NSTimeZone defaultTimeZone];
	NSDateFormatter * timeFormat =
	[NSDateFormatter withFormat:@"h:mm a z" timeZone:timeZone];
	NSDateFormatter * dateFormat2 =
	[NSDateFormatter withFormat:@"EEE, d MMM YYYY h:mm a z" timeZone:timeZone];
	NSString * dateString;
	NSDate * date;

	//	Now add translation maps, fill in missing cells from sims
	NSDictionary * sims = [self weatherBySimulation];
	NSMutableDictionary * temp = nil;

	temp = [NSMutableDictionary dictionary];
	dateString = dict[@"city"][@"sun"][@"_rise"];
	date = [utc_format dateFromString:dateString];
	temp[@"sunrise"] = [timeFormat stringFromDate:date];

	dateString = dict[@"city"][@"sun"][@"_set"];
	date = [utc_format dateFromString:dateString];
	temp[@"sunset"] = [timeFormat stringFromDate:date];
	dict[@"astronomy"] = temp;

	temp = [NSMutableDictionary dictionary];
	temp[@"humidity"] = dict[@"humidity"][@"_value"];
	temp[@"pressure"] = dict[@"pressure"][@"_value"];
//	temp[@"rising"] = TODO: pressure
//	temp[@"visibility"] = TODO: distance
	dict[@"atmosphere"] = temp;

	temp = [NSMutableDictionary dictionary];

	//	Use ydlcodes to find a matching weather code key and text
	NSString * text = dict[@"weather"][@"_value"];
	NSDictionary * ydl = getModelForWeatherText(text);
	NSNumber * code = dict[@"weather"][@"_number"];
	NSNumber * rank = ydl[@"rank"];

	temp[@"code"] = code;

	dateString = dict[@"lastupdate"][@"_value"];
	date = [utc_format dateFromString:dateString];
	temp[@"date"] = [dateFormat2 stringFromDate:date];

	temp[@"temp"] = dict[@"temperature"][@"_value"];
	temp[@"text"] = text;
	temp[@"rank"] = rank;
	dict[@"condition"] = temp;

	temp = [NSMutableDictionary dictionary];
	temp[@"description"] = dict[@"weather"][@"_value"];
	temp[@"code"] = dict[@"weather"][@"_number"];

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

	//	Unify all dates to the model format from UTC format
	NSTimeZone * utcZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSDateFormatter * utc_format = [NSDateFormatter withFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'" timeZone:utcZone];

	NSTimeZone * timeZone = [NSTimeZone defaultTimeZone];
	NSDateFormatter * dateFormat2 =
	[NSDateFormatter withFormat:@"EEE, d MMM YYYY h:mm a z" timeZone:timeZone];
	NSString * dateString;
	NSDate * date;

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

	//	Use ydlcodes to find a matching weather code key and text
	NSString * text = dict[@"current_observation"][@"weather"];
	NSDictionary * ydl = getModelForWeatherText(text);
	NSNumber * code = ydl[wCode];
	NSNumber * rank = ydl[wRank];

	temp = [NSMutableDictionary dictionary];
	temp[@"code"] = code;
	temp[@"text"] = text;
	temp[@"rank"] = rank;

	dateString = dict[@"current_observation"][@"observation_time"];
	date = [utc_format dateFromString:dateString];
	temp[@"date"] = [dateFormat2 stringFromDate:date];

	temp[@"temp"] = dict[@"current_observation"][@"temp_f"];
	dict[@"condition"] = temp;

	temp = [NSMutableDictionary dictionary];
	temp[@"description"] = dict[@"current_observation"][@"image"][@"title"];
	temp[@"code"] = code;
	temp[@"date"] = sims[@"forecast"][@"date"];
	temp[@"day"] = sims[@"forecast"][@"day"];;
	temp[@"day"][@"high"] = dict[@"current_observation"][@"windchill_f"];
	temp[@"day"][@"low"] = dict[@"current_observation"][@"windchill_f"];
	temp[@"text"] = text;
	dict[@"forecast"] = temp;

//	image - already set
	dict[@"item"] = dict[@"current_observation"][@"observation_time"];
	dict[@"language"] = @"en-us";

	dateString = dict[@"current_observation"][@"observation_time"];
	date = [utc_format dateFromString:dateString];
	dict[@"lastBuildDate"] = [dateFormat2 stringFromDate:date];

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

	[vals setObject:[[NSHost currentHost] localizedName] forKey:@"city"];
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
	[vals setObject:@"2" forKey:@"rank"];

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

- (id)weatherBy:(WeatherProvider_t)provider
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

#pragma mark -

// https://gist.githubusercontent.com/darkseed/1261842/raw/05384407c99a6981b1743053c9458977bf28d782/NSString+Soundex.m
//#import "NSString+Soundex.h"
@implementation NSString (Soundex)

static NSArray* soundexCharSets = nil;

- (void)		initSoundex
{
	if( soundexCharSets == nil )
	{
		NSMutableArray* cs = [NSMutableArray array];
		NSCharacterSet* charSet;
		
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"aeiouhw"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"bfpv"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"cgjkqsxz"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"dt"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"l"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"mn"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"r"];
		[cs addObject:charSet];

		soundexCharSets = cs;//[cs retain];
	}
}


- (NSString *)	stringByRemovingCharactersInSet:(NSCharacterSet*) charSet options:(unsigned) mask
{
	NSRange				range;
	NSMutableString*	newString = [NSMutableString string];
	NSUInteger			len = [self length];
	
	mask &= ~NSBackwardsSearch;
	range = NSMakeRange (0, len);
	while (range.length)
	{
		NSRange substringRange;
		NSUInteger pos = range.location;
		
		range = [self rangeOfCharacterFromSet:charSet options:mask range:range];
		if (range.location == NSNotFound)
			range = NSMakeRange (len, 0);
		
		substringRange = NSMakeRange (pos, range.location - pos);
		[newString appendString:[self substringWithRange:substringRange]];
		
		range.location += range.length;
		range.length = len - range.location;
	}
	
	return newString;
}


- (NSString *)	stringByRemovingCharactersInSet:(NSCharacterSet*) charSet
{
	return [self stringByRemovingCharactersInSet:charSet options:0];
}


- (unsigned)	soundexValueForCharacter:(unichar) aCharacter
{
	// returns the soundex mapping for the first character in the string. If the value returned is 0, the character should be discarded.
	
	unsigned		indx;
	NSCharacterSet* cs;
	
	for( indx = 0; indx < [soundexCharSets count]; ++indx )
	{
		cs = [soundexCharSets objectAtIndex:indx];
		
		if([cs characterIsMember:aCharacter])
			return indx;
	}
	
	return 0;
}


- (NSString*)	soundexString
{
	// returns the Soundex representation of the string.
	/*
	 
	 Replace consonants with digits as follows (but do not change the first letter):
	 b, f, p, v => 1
	 c, g, j, k, q, s, x, z => 2
	 d, t => 3
	 l => 4
	 m, n => 5
	 r => 6
	 Collapse adjacent identical digits into a single digit of that value.
	 Remove all non-digits after the first letter.
	 Return the starting letter and the first three remaining digits. If needed, append zeroes to make it a letter and three digits.
	 
	 */
	
	[self initSoundex];
	
	if([self length] > 0)
	{
		NSMutableString* soundexStr = [NSMutableString string];
		
		// strip whitespace and convert to lower case
		
		NSString*	workingString = [[self lowercaseString] stringByRemovingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		unsigned	indx, soundValue, previousSoundValue = 0;
		
		// include first character
		
		[soundexStr appendString:[workingString substringToIndex:1]];
		
		// convert up to 3 more significant characters
		
		for( indx = 1; indx < [workingString length]; ++indx )
		{
			soundValue = [self soundexValueForCharacter:[workingString characterAtIndex:indx]];
			
			if( soundValue > 0 && soundValue != previousSoundValue )
				[soundexStr appendString:[NSString stringWithFormat:@"%d", soundValue]];
			
			previousSoundValue = soundValue;
			
			// if we've got four characters, don't need to scan any more
			
			if([soundexStr length] >= 4)
				break;
		}
		
		// if < 4 characters, need to pad the string with zeroes
		
		while([soundexStr length] < 4)
			[soundexStr appendString:@"0"];
		
		//NSLog(@"soundex for '%@' = %@", self, soundexStr );
		
		return soundexStr;
	}
	else
		return @"";
}


- (BOOL)		soundsLikeString:(NSString*) aString
{
	return [[self soundexString] isEqualToString:[aString soundexString]];
}
@end
