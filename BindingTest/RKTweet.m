
#import "RKTweet.h"

@implementation RKTweet

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (ID: %@)", self.text, self.statusID];
}

@end
