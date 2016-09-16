#import <UIKit/UIKit.h>

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString *referenceHTML;
@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@end
