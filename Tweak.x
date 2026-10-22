#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// UI-only debug overlay. This file intentionally contains no game hooks,
// memory access, aimbot, ESP, or offset code.

static UIWindow *gOverlayWindow = nil;
static UIButton *gFloatButton = nil;
static UIView *gPanel = nil;
static WKWebView *gWebView = nil;
static int gInstallAttempts = 0;

@interface RAACHEATPassThroughView : UIView
@end

@implementation RAACHEATPassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
@end

@interface RAACHEATRootController : UIViewController
- (void)raacheatOpen;
- (void)raacheatClose;
- (void)raacheatPan:(UIPanGestureRecognizer *)pan;
@end

static NSString *RAACHEATCatalogPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *bases = @[
        @"/var/jb/Library/Application Support/RAACHEATMenuDebug",
        @"/Library/Application Support/RAACHEATMenuDebug"
    ];
    for (NSString *base in bases) {
        NSString *path = [base stringByAppendingPathComponent:@"index.html"];
        if ([fm fileExistsAtPath:path]) {
            return path;
        }
    }
    return [bases.lastObject stringByAppendingPathComponent:@"index.html"];
}

static void RAACHEATOpenPanel(void) {
    if (!gOverlayWindow) {
        return;
    }

    RAACHEATRootController *root = (RAACHEATRootController *)gOverlayWindow.rootViewController;
    if (!root) {
        return;
    }

    if (gPanel) {
        gPanel.hidden = NO;
        return;
    }

    CGRect bounds = root.view.bounds;
    gPanel = [[UIView alloc] initWithFrame:bounds];
    gPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gPanel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.94];
    [root.view addSubview:gPanel];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 56)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    header.backgroundColor = [UIColor colorWithRed:0.04 green:0.07 blue:0.10 alpha:1.0];
    [gPanel addSubview:header];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, bounds.size.width - 92, 40)];
    title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    title.text = @"RAACHEAT Menu Code - Debug";
    title.textColor = [UIColor colorWithRed:0.31 green:0.94 blue:0.65 alpha:1.0];
    title.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightBold];
    title.adjustsFontSizeToFitWidth = YES;
    [header addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(bounds.size.width - 76, 8, 64, 40);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close setTitle:@"Close" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [close addTarget:root action:@selector(raacheatClose) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:close];

    CGRect webFrame = CGRectMake(0, 56, bounds.size.width, bounds.size.height - 56);
    gWebView = [[WKWebView alloc] initWithFrame:webFrame];
    gWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gWebView.opaque = NO;
    gWebView.backgroundColor = [UIColor blackColor];
    gWebView.scrollView.backgroundColor = [UIColor blackColor];
    [gPanel addSubview:gWebView];

    NSURL *url = [NSURL fileURLWithPath:RAACHEATCatalogPath()];
    [gWebView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
}

@implementation RAACHEATRootController

- (void)loadView {
    self.view = [[RAACHEATPassThroughView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)raacheatOpen {
    RAACHEATOpenPanel();
}

- (void)raacheatClose {
    if (gPanel) {
        gPanel.hidden = YES;
    }
}

- (void)raacheatPan:(UIPanGestureRecognizer *)pan {
    UIView *view = pan.view;
    CGPoint translation = [pan translationInView:view.superview];
    view.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:view.superview];
}

@end

static void RAACHEATInstallOverlay(void) {
    if (gOverlayWindow || gInstallAttempts++ > 20) {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if (!app) {
        return;
    }

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                gOverlayWindow = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
                break;
            }
        }
        if (!gOverlayWindow) {
            UIWindow *existing = app.windows.firstObject;
            if (existing.windowScene) {
                gOverlayWindow = [[UIWindow alloc] initWithWindowScene:existing.windowScene];
            }
        }
    }

    if (!gOverlayWindow) {
        gOverlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    gOverlayWindow.windowLevel = UIWindowLevelAlert + 1.0;
    gOverlayWindow.backgroundColor = [UIColor clearColor];
    gOverlayWindow.rootViewController = [[RAACHEATRootController alloc] init];
    gOverlayWindow.hidden = NO;

    RAACHEATRootController *root = (RAACHEATRootController *)gOverlayWindow.rootViewController;
    CGRect screen = [UIScreen mainScreen].bounds;

    gFloatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    gFloatButton.frame = CGRectMake(screen.size.width - 66, 96, 52, 52);
    gFloatButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    gFloatButton.backgroundColor = [UIColor colorWithRed:0.06 green:0.13 blue:0.10 alpha:0.94];
    gFloatButton.layer.cornerRadius = 26.0;
    gFloatButton.layer.borderWidth = 1.0;
    gFloatButton.layer.borderColor = [UIColor colorWithRed:0.31 green:0.94 blue:0.65 alpha:0.85].CGColor;
    [gFloatButton setTitle:@"R" forState:UIControlStateNormal];
    [gFloatButton setTitleColor:[UIColor colorWithRed:0.31 green:0.94 blue:0.65 alpha:1.0] forState:UIControlStateNormal];
    gFloatButton.titleLabel.font = [UIFont monospacedSystemFontOfSize:22 weight:UIFontWeightBold];
    [gFloatButton addTarget:root action:@selector(raacheatOpen) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:root action:@selector(raacheatPan:)];
    pan.cancelsTouchesInView = NO;
    [gFloatButton addGestureRecognizer:pan];

    [root.view addSubview:gFloatButton];
}

static void RAACHEATTryInstall(void) {
    if (gOverlayWindow) {
        return;
    }
    RAACHEATInstallOverlay();
    if (!gOverlayWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RAACHEATTryInstall();
        });
    }
}

%ctor {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RAACHEATTryInstall();
        });
    }
}
