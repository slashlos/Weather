//
//  Weather-Private.h
//  Weather
//
//  Created by Carlos Santiago on 8/28/16.
//  Copyright © 2016 Carlos D. Santiago. All rights reserved.
//
//	Split from Extras.h
//
//	Contains confidential usert tags

//	Yahoo YDL API Keys - public api currentlty used
#ifndef ydnDefaultKey
#define	ydnDefaultKey	(@"your-Yahoo!-default key")	// currently NYI
#endif

#ifdef	ydnSecretKey
#define	ydnSecretKey	(@"your-Yahoo!-developer-id")	// currently NYI
#endif

//	Open Weather Map API Key
#ifndef	owmDefaultKey
#define	owmDefaultKey	(@"open-weather-map-api-key")
#endif

#ifndef	owmAppKey
#define	owmAppKey		(@"your-open-weather-map-applic-key")
#endif

//	Wunderground API key
#ifndef	wuAppKey
#define	wuAppKey		(@"your-weather-underground-api-key")
#endif
