//
//  Appcelerator Titanium Mobile
//  WARNING: this is a generated file and should not be modified
//

#import <UIKit/UIKit.h>
#define _QUOTEME(x) #x
#define STRING(x) _QUOTEME(x)

NSString * const TI_APPLICATION_DEPLOYTYPE = @"development";
NSString * const TI_APPLICATION_ID = @"com.shenglongelectricv.app";
NSString * const TI_APPLICATION_PUBLISHER = @"peter";
NSString * const TI_APPLICATION_URL = @"http://www.shenglong-electric.com.cn/";
NSString * const TI_APPLICATION_NAME = @"shenglong-electricv";
NSString * const TI_APPLICATION_VERSION = @"1.0.0";
NSString * const TI_APPLICATION_DESCRIPTION = @"盛隆电气";
NSString * const TI_APPLICATION_COPYRIGHT = @"2013 by peter";
NSString * const TI_APPLICATION_GUID = @"ade3f3f4-74e5-4292-b855-94a6c148f0a7";
BOOL const TI_APPLICATION_ANALYTICS = true;

#ifdef TARGET_IPHONE_SIMULATOR
NSString * const TI_APPLICATION_RESOURCE_DIR = @"";
#endif

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

#ifdef __LOG__ID__
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *logPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%s.log",STRING(__LOG__ID__)]];
	freopen([logPath cStringUsingEncoding:NSUTF8StringEncoding],"w+",stderr);
	fprintf(stderr,"[INFO] Application started\n");
#endif

	int retVal = UIApplicationMain(argc, argv, nil, @"TiApp");
    [pool release];
    return retVal;
}
