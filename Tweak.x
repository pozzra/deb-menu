#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Rxaa is a UI-only debug overlay. It intentionally contains no game hooks,
// memory access, aimbot, ESP, or offset code.

static UIWindow *gOverlayWindow = nil;
static UIWindow *gButtonWindow = nil;
static UIButton *gFloatButton = nil;
static UINavigationController *gMenuNav = nil;
static UITapGestureRecognizer *gOpenGesture = nil;
static UIWindow *gGestureWindow = nil;
static UIWindow *gPreviousKeyWindow = nil;
static int gInstallAttempts = 0;

static CGFloat const kRXAAFloatButtonSize = 52.0;
static CGFloat const kRXAAFloatButtonMargin = 10.0;
static NSString * const kRXAAFloatCenterXKey = @"rxaa.float.centerX";
static NSString * const kRXAAFloatCenterYKey = @"rxaa.float.centerY";
static CGPoint gButtonPanStartCenter;
static CGPoint gButtonPanStartPoint;

static void RAACHEATAttachWindowToScene(void);

@interface RAACHEATPassThroughView : UIView
@end

@implementation RAACHEATPassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
@end

static UIColor *RXAAGreen(void) {
    return [UIColor colorWithRed:0.31 green:0.94 blue:0.65 alpha:1.0];
}

static UIColor *RXAABackground(void) {
    return [UIColor blackColor];
}

static NSString *RAACHEATResourcePath(NSString *name) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *bases = @[
        @"/var/jb/Library/Application Support/RAACHEATMenuDebug",
        @"/private/var/jb/Library/Application Support/RAACHEATMenuDebug",
        @"/Library/Application Support/RAACHEATMenuDebug"
    ];
    for (NSString *base in bases) {
        NSString *path = [base stringByAppendingPathComponent:name];
        if ([fm fileExistsAtPath:path]) {
            return path;
        }
    }
    return nil;
}

static NSString *RAACHEATCatalogPath(void) {
    NSString *path = RAACHEATResourcePath(@"index.html");
    return path ? path : @"/Library/Application Support/RAACHEATMenuDebug/index.html";
}

typedef struct {
    const char *label;
    const char *category;
    const char *kind;
} RXAAEmbeddedFeature;

static const RXAAEmbeddedFeature kRXAAEmbeddedFeatures[] = {
    {"AIMLOCK 100%", "aimbot", "toggle"},
    {"AIMBOT 360", "aimbot", "toggle"},
    {"AIMBOT 180", "aimbot", "toggle"},
    {"WALLHACK", "visuals", "toggle"},
    {"NO RECOIL 100%", "memory", "toggle"},
    {"SPEED", "memory", "toggle"},
    {"SPEED EPIC", "memory", "toggle"},
    {"MOD HACK", "settings", "label"},
    {"AimBot / AimLock Enable", "aimbot", "toggle"},
    {"Aim FOV Radius", "aimbot", "slider"},
    {"Aim Lock Distance", "aimbot", "slider"},
    {"Aim Smooth", "aimbot", "slider"},
    {"Aim.AutoShoot", "aimbot", "config-key"},
    {"Aim.AutoShootDistance", "aimbot", "config-key"},
    {"Aim.Cross", "aimbot", "config-key"},
    {"Aim.Enable", "aimbot", "config-key"},
    {"Aim.Fov", "aimbot", "config-key"},
    {"Aim.IgnoreBot", "aimbot", "config-key"},
    {"Aim.IgnoreKnocked", "aimbot", "config-key"},
    {"Aim.InstantAim", "aimbot", "config-key"},
    {"Aim.MaxDistance", "aimbot", "config-key"},
    {"Aim.Power", "aimbot", "config-key"},
    {"Aim.Silent360", "aimbot", "config-key"},
    {"Aim.SilentAim", "aimbot", "config-key"},
    {"Aim.SilentDistance", "aimbot", "config-key"},
    {"Aim.Smooth", "aimbot", "config-key"},
    {"Aim.TargetBone", "aimbot", "config-key"},
    {"Aim.TeamCheck", "aimbot", "config-key"},
    {"Aim.Trigger", "aimbot", "config-key"},
    {"Aim.VisCheck", "aimbot", "config-key"},
    {"Aimbot", "aimbot", "label"},
    {"AUTOLOCK // RADAR TRACK  ", "aimbot", "label"},
    {"Draw Aim FOV Circle", "aimbot", "toggle"},
    {"Esp Bone", "aimbot", "label"},
    {"Follow Hardness (Power)", "aimbot", "label"},
    {"Ignore Knocked", "aimbot", "toggle"},
    {"Instant AimLock (Direct Snap)", "aimbot", "toggle"},
    {"QUANTUM AIM ", "aimbot", "label"},
    {"Red tracers, white bones, yellow labels and health above the head.", "aimbot", "label"},
    {"Settings.Unlock120FPS", "aimbot", "config-key"},
    {"Silent 360", "aimbot", "toggle"},
    {"Silent Aim (Magic Bullet)", "aimbot", "toggle"},
    {"Silent Aim Distance", "aimbot", "slider"},
    {"Target Bone", "aimbot", "combo"},
    {"TARGET FILTERS", "aimbot", "label"},
    {"Teammates excluded (always)", "aimbot", "label"},
    {"Trigger Condition", "aimbot", "combo"},
    {"Unlock 120 FPS", "aimbot", "label"},
    {"Video palette: white player tracers, green bot tracers, red/green bones and colored name plates.", "aimbot", "label"},
    {"Box Color", "visuals", "label"},
    {"CYBER ESP ", "visuals", "label"},
    {"Distance", "visuals", "label"},
    {"Esp Box", "visuals", "label"},
    {"Esp Count", "visuals", "label"},
    {"Esp Distance", "visuals", "label"},
    {"Esp Health", "visuals", "label"},
    {"ESP Layout", "visuals", "label"},
    {"Esp Line", "visuals", "label"},
    {"Esp Name", "visuals", "label"},
    {"ESP.Alert", "visuals", "config-key"},
    {"ESP.Bot", "visuals", "config-key"},
    {"ESP.Box", "visuals", "config-key"},
    {"ESP.BoxColor.w", "visuals", "config-key"},
    {"ESP.BoxColor.x", "visuals", "config-key"},
    {"ESP.BoxColor.y", "visuals", "config-key"},
    {"ESP.BoxColor.z", "visuals", "config-key"},
    {"ESP.CrownArrows", "visuals", "config-key"},
    {"ESP.CrownRing", "visuals", "config-key"},
    {"ESP.CrownWeapons", "visuals", "config-key"},
    {"ESP.Distance", "visuals", "config-key"},
    {"ESP.EnemyOnly", "visuals", "config-key"},
    {"ESP.Knocked", "visuals", "config-key"},
    {"ESP.Line", "visuals", "config-key"},
    {"ESP.LineBelow", "visuals", "config-key"},
    {"ESP.LineColor.w", "visuals", "config-key"},
    {"ESP.LineColor.x", "visuals", "config-key"},
    {"ESP.LineColor.y", "visuals", "config-key"},
    {"ESP.LineColor.z", "visuals", "config-key"},
    {"ESP.LinePosition", "visuals", "config-key"},
    {"ESP.LineThickness", "visuals", "config-key"},
    {"ESP.MaxDistance", "visuals", "config-key"},
    {"ESP.Name", "visuals", "config-key"},
    {"ESP.Skeleton", "visuals", "config-key"},
    {"ESP.SkeletonColor.w", "visuals", "config-key"},
    {"ESP.SkeletonColor.x", "visuals", "config-key"},
    {"ESP.SkeletonColor.y", "visuals", "config-key"},
    {"ESP.SkeletonColor.z", "visuals", "config-key"},
    {"ESP.SkeletonDebug", "visuals", "config-key"},
    {"ESP.Vehicle", "visuals", "config-key"},
    {"Hide ESP (Screen & Recording)", "visuals", "label"},
    {"Line Color", "visuals", "label"},
    {"Line Position", "visuals", "label"},
    {"RADAR FX", "visuals", "label"},
    {"Skeleton Color", "visuals", "label"},
    {"Style Box", "visuals", "label"},
    {"Vehicle Esp", "visuals", "label"},
    {"Visuals", "visuals", "label"},
    {"Memory", "memory", "label"},
    {"Memory Engine", "memory", "label"},
    {"RegionSwitchButton", "memory", "label"},
    {"SELECT SEARCH REGION", "memory", "label"},
    {"Speed Multiplier", "memory", "label"},
    {"Speed.Multiplier", "memory", "config-key"},
    {"CONFIGURATION", "settings", "label"},
    {"HUD CONFIG & FX ", "settings", "label"},
    {"LOAD CONFIG", "settings", "label"},
    {"MenuHeaderClose", "settings", "label"},
    {"Package", "settings", "label"},
    {"Runtime", "settings", "label"},
    {"SAVE PRESET", "settings", "label"},
    {"Settings", "settings", "label"},
    {"Settings.HideRecording", "settings", "config-key"},
    {"Choose the optimal scanning region for your device and game version:", "help", "help"},
    {"Note: You can switch regions anytime from the top bar.", "help", "help"},
    {"Select the game memory search region for this session.", "help", "help"},
    {"Tap to cycle search region: OTHER -> ANONYMOUS -> C_ALLOC", "help", "help"},
};

static NSArray<NSDictionary *> *RXAAEmbeddedCatalogFeatures(void) {
    NSUInteger count = (NSUInteger)(sizeof(kRXAAEmbeddedFeatures) / sizeof(kRXAAEmbeddedFeatures[0]));
    NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        RXAAEmbeddedFeature feature = kRXAAEmbeddedFeatures[i];
        [result addObject:@{
            @"label": [NSString stringWithUTF8String:feature.label],
            @"category": [NSString stringWithUTF8String:feature.category],
            @"kind": [NSString stringWithUTF8String:feature.kind]
        }];
    }
    return result;
}

static NSArray<NSString *> *RXAACatalogCategories(void) {
    return @[@"aimbot", @"visuals", @"memory", @"settings", @"help"];
}

static NSArray<NSDictionary *> *RXAACatalogFeatures(void) {
    static NSArray<NSDictionary *> *features = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = RAACHEATResourcePath(@"menu_catalog.json");
        NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
        id root = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSArray *items = nil;
        if ([root isKindOfClass:[NSDictionary class]]) {
            id value = ((NSDictionary *)root)[@"items"];
            if ([value isKindOfClass:[NSArray class]]) {
                items = (NSArray *)value;
            }
        }

        NSSet<NSString *> *wanted = [NSSet setWithArray:RXAACatalogCategories()];
        NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
        for (id item in items) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSDictionary *entry = (NSDictionary *)item;
            NSString *category = entry[@"category"];
            NSString *label = entry[@"label"];
            if (![category isKindOfClass:[NSString class]] ||
                ![label isKindOfClass:[NSString class]] ||
                ![wanted containsObject:category]) {
                continue;
            }
            [result addObject:entry];
        }
        if (result.count == 0) {
            NSLog(@"[Rxaa] catalog JSON unavailable at %@; using embedded features", path);
            result = [RXAAEmbeddedCatalogFeatures() mutableCopy];
        } else {
            NSLog(@"[Rxaa] loaded %lu catalog features from %@",
                  (unsigned long)result.count, path);
        }
        features = [result copy];
    });
    return features ? features : @[];
}

static NSArray<NSDictionary *> *RXAACatalogFeaturesForCategory(NSString *category) {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    for (NSDictionary *item in RXAACatalogFeatures()) {
        if ([item[@"category"] isEqualToString:category]) {
            [result addObject:item];
        }
    }
    return result;
}

static NSString *RXAACatalogFeatureKey(NSDictionary *item) {
    NSString *category = item[@"category"];
    NSString *label = item[@"label"];
    if (!category) {
        category = @"feature";
    }
    if (!label) {
        label = @"unknown";
    }
    return [NSString stringWithFormat:@"rxaa.catalog.%@.%@", category, label];
}

static BOOL RXAACatalogFeatureIsActionable(NSDictionary *item) {
    NSString *kind = item[@"kind"];
    return [kind isEqualToString:@"toggle"] ||
           [kind isEqualToString:@"slider"] ||
           [kind isEqualToString:@"combo"] ||
           [kind isEqualToString:@"config-key"];
}

@interface RXAAMenuViewController : UITableViewController
@end

@interface RXAACatalogFeatureViewController : UITableViewController
- (void)catalogSwitchChanged:(UISwitch *)sender;
@end

@interface RXAACatalogSwitch : UISwitch
@property (nonatomic, copy) NSString *featureKey;
@end

@interface RXAACatalogViewController : UIViewController
@property (nonatomic, strong) WKWebView *webView;
@end

@interface RAACHEATRootController : UIViewController <UIGestureRecognizerDelegate>
- (void)raacheatOpen;
@end

@interface RAACHEATButtonController : UIViewController
- (void)raacheatOpen;
- (void)raacheatPan:(UIPanGestureRecognizer *)pan;
@end

static UIWindow *RAACHEATKeyWindowForScene(UIWindowScene *scene) {
    if (@available(iOS 13.0, *)) {
        if (scene) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
        for (UIScene *connected in [UIApplication sharedApplication].connectedScenes) {
            if (![connected isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            for (UIWindow *window in ((UIWindowScene *)connected).windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return nil;
}

static CGRect RAACHEATScreenBounds(void) {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = gOverlayWindow.windowScene;
        if (scene) {
            CGRect bounds = scene.coordinateSpace.bounds;
            if (!CGRectIsEmpty(bounds)) {
                return bounds;
            }
        }
    }
    return [UIScreen mainScreen].bounds;
}

static UIEdgeInsets RAACHEATScreenSafeInsets(void) {
    if (@available(iOS 11.0, *)) {
        UIWindow *key = RAACHEATKeyWindowForScene(nil);
        if (key && key != gOverlayWindow && key != gButtonWindow) {
            return key.safeAreaInsets;
        }
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window != gOverlayWindow && window != gButtonWindow && !window.hidden) {
                return window.safeAreaInsets;
            }
        }
    }
    return UIEdgeInsetsZero;
}

static CGPoint RAACHEATClampFloatButtonCenter(CGPoint center) {
    CGRect screen = RAACHEATScreenBounds();
    if (CGRectIsEmpty(screen)) {
        return center;
    }
    UIEdgeInsets insets = RAACHEATScreenSafeInsets();
    CGFloat half = kRXAAFloatButtonSize * 0.5;
    CGFloat minX = screen.origin.x + insets.left + kRXAAFloatButtonMargin + half;
    CGFloat maxX = screen.origin.x + screen.size.width - insets.right -
                   kRXAAFloatButtonMargin - half;
    CGFloat minY = screen.origin.y + insets.top + kRXAAFloatButtonMargin + half;
    CGFloat maxY = screen.origin.y + screen.size.height - insets.bottom -
                   kRXAAFloatButtonMargin - half;

    if (maxX < minX) {
        minX = maxX = CGRectGetMidX(screen);
    }
    if (maxY < minY) {
        minY = maxY = CGRectGetMidY(screen);
    }

    center.x = MAX(minX, MIN(maxX, center.x));
    center.y = MAX(minY, MIN(maxY, center.y));
    return center;
}

static void RAACHEATSaveFloatButtonPosition(void) {
    if (!gButtonWindow) {
        return;
    }
    CGRect screen = RAACHEATScreenBounds();
    if (CGRectIsEmpty(screen)) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat x = (gButtonWindow.center.x - screen.origin.x) / screen.size.width;
    CGFloat y = (gButtonWindow.center.y - screen.origin.y) / screen.size.height;
    [defaults setDouble:x forKey:kRXAAFloatCenterXKey];
    [defaults setDouble:y forKey:kRXAAFloatCenterYKey];
}

static void RAACHEATRestoreFloatButtonPosition(void) {
    if (!gButtonWindow) {
        return;
    }
    CGRect screen = RAACHEATScreenBounds();
    if (CGRectIsEmpty(screen)) {
        return;
    }

    UIEdgeInsets insets = RAACHEATScreenSafeInsets();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *savedX = [defaults objectForKey:kRXAAFloatCenterXKey];
    NSNumber *savedY = [defaults objectForKey:kRXAAFloatCenterYKey];
    CGPoint center = CGPointZero;

    if (savedX && savedY) {
        center.x = screen.origin.x + (CGFloat)[savedX doubleValue] * screen.size.width;
        center.y = screen.origin.y + (CGFloat)[savedY doubleValue] * screen.size.height;
    } else {
        center.x = screen.origin.x + screen.size.width - insets.right -
                   kRXAAFloatButtonMargin - (kRXAAFloatButtonSize * 0.5);
        center.y = screen.origin.y + insets.top + kRXAAFloatButtonMargin + 92.0 +
                   (kRXAAFloatButtonSize * 0.5);
    }

    CGRect frame = gButtonWindow.frame;
    frame.size = CGSizeMake(kRXAAFloatButtonSize, kRXAAFloatButtonSize);
    gButtonWindow.frame = frame;
    UIView *buttonView = gButtonWindow.rootViewController.view;
    if (buttonView) {
        buttonView.frame = CGRectMake(0.0, 0.0,
                                      kRXAAFloatButtonSize, kRXAAFloatButtonSize);
        if (gFloatButton) {
            gFloatButton.frame = buttonView.bounds;
        }
    }
    gButtonWindow.center = RAACHEATClampFloatButtonCenter(center);
}

static void RAACHEATRestorePreviousKeyWindow(void) {
    if (gOverlayWindow) {
        gOverlayWindow.hidden = YES;
    }
    if (gButtonWindow) {
        gButtonWindow.hidden = NO;
        gButtonWindow.windowLevel = UIWindowLevelAlert + 101.0;
        RAACHEATRestoreFloatButtonPosition();
    }

    UIWindow *target = gPreviousKeyWindow;
    if (!target || target == gOverlayWindow || target == gButtonWindow || target.hidden) {
        target = RAACHEATKeyWindowForScene(nil);
        if (target == gOverlayWindow || target == gButtonWindow || target.hidden) {
            target = nil;
        }
    }
    if (!target) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window != gOverlayWindow && window != gButtonWindow && !window.hidden) {
                target = window;
                break;
            }
        }
    }
    if (target) {
        [target makeKeyWindow];
        NSLog(@"[Rxaa] game key window restored: %@", target);
    } else if (gOverlayWindow) {
        [gOverlayWindow resignKeyWindow];
        NSLog(@"[Rxaa] no game key window found; overlay resigned key");
    }
    gPreviousKeyWindow = nil;
}

static void RAACHEATRefreshOverlayBounds(void) {
    if (!gOverlayWindow) {
        return;
    }

    CGRect bounds = CGRectZero;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = gOverlayWindow.windowScene;
        if (scene) {
            bounds = scene.coordinateSpace.bounds;
        }
    }
    if (CGRectIsEmpty(bounds)) {
        bounds = [UIScreen mainScreen].bounds;
    }
    if (CGRectIsEmpty(bounds)) {
        return;
    }

    gOverlayWindow.frame = bounds;
    UIViewController *root = gOverlayWindow.rootViewController;
    root.view.frame = gOverlayWindow.bounds;
    if (gButtonWindow) {
        RAACHEATRestoreFloatButtonPosition();
    }
}

static void RAACHEATOpenPanel(void) {
    if (!gOverlayWindow) {
        NSLog(@"[Rxaa] open ignored: overlay window is nil");
        return;
    }

    UIViewController *root = gOverlayWindow.rootViewController;
    if (!root) {
        NSLog(@"[Rxaa] open ignored: overlay root is nil");
        return;
    }

    if (gMenuNav) {
        if (root.presentedViewController == gMenuNav) {
            NSLog(@"[Rxaa] open ignored: menu already presented");
            return;
        }
        gMenuNav = nil;
    }

    if (root.presentedViewController) {
        NSLog(@"[Rxaa] open ignored: another controller is presented: %@", root.presentedViewController);
        return;
    }

    NSLog(@"[Rxaa] opening menu");
    RAACHEATAttachWindowToScene();
    RAACHEATRefreshOverlayBounds();
    gOverlayWindow.hidden = NO;
    gOverlayWindow.windowLevel = UIWindowLevelAlert + 100.0;
    if (gButtonWindow) {
        gButtonWindow.hidden = YES;
    }
    gPreviousKeyWindow = RAACHEATKeyWindowForScene(nil);
    if (gPreviousKeyWindow == gOverlayWindow || gPreviousKeyWindow == gButtonWindow) {
        gPreviousKeyWindow = nil;
    }
    if (!gPreviousKeyWindow) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window != gOverlayWindow && window != gButtonWindow && !window.hidden) {
                gPreviousKeyWindow = window;
                break;
            }
        }
    }
    [gOverlayWindow makeKeyAndVisible];

    RXAAMenuViewController *menu = [[RXAAMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:menu];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    nav.view.backgroundColor = RXAABackground();
    gMenuNav = nav;
    [root presentViewController:nav animated:YES completion:^{
        if (root.presentedViewController != nav) {
            NSLog(@"[Rxaa] presentation did not complete");
            gMenuNav = nil;
            RAACHEATRestorePreviousKeyWindow();
        }
    }];
}

@implementation RAACHEATRootController

- (void)loadView {
    self.view = [[RAACHEATPassThroughView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        (void)context;
        RAACHEATRefreshOverlayBounds();
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        (void)context;
        RAACHEATRefreshOverlayBounds();
    }];
}

- (void)raacheatOpen {
    RAACHEATOpenPanel();
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

@implementation RAACHEATButtonController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                         kRXAAFloatButtonSize,
                                                         kRXAAFloatButtonSize)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (gFloatButton) {
        gFloatButton.frame = self.view.bounds;
    }
}

- (void)raacheatOpen {
    RAACHEATOpenPanel();
}

- (void)raacheatPan:(UIPanGestureRecognizer *)pan {
    if (!gButtonWindow) {
        return;
    }

    UIView *reference = gOverlayWindow ?: self.view;
    if (pan.state == UIGestureRecognizerStateBegan) {
        gButtonPanStartCenter = gButtonWindow.center;
        gButtonPanStartPoint = [pan locationInView:reference];
        gButtonWindow.hidden = NO;
        [UIView animateWithDuration:0.12
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            gFloatButton.alpha = 0.82;
        } completion:nil];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [pan locationInView:reference];
        CGPoint center = CGPointMake(
            gButtonPanStartCenter.x + (point.x - gButtonPanStartPoint.x),
            gButtonPanStartCenter.y + (point.y - gButtonPanStartPoint.y));
        gButtonWindow.center = RAACHEATClampFloatButtonCenter(center);
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled ||
               pan.state == UIGestureRecognizerStateFailed) {
        gButtonWindow.center = RAACHEATClampFloatButtonCenter(gButtonWindow.center);
        RAACHEATSaveFloatButtonPosition();
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            gFloatButton.alpha = 1.0;
        } completion:nil];
    }
}

@end

static NSArray<NSString *> *RXAAFeatureTitles(void) {
    return @[@"AimLock", @"ESP", @"Radar"];
}

static NSArray<NSString *> *RXAAFeatureKeys(void) {
    return @[@"rxaa.aimlock", @"rxaa.esp", @"rxaa.radar"];
}

@implementation RXAAMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Rxaa";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Close"
                style:UIBarButtonItemStyleDone
                target:self
                action:@selector(closeMenu)];

    self.tableView.backgroundColor = RXAABackground();
    self.tableView.separatorColor = [UIColor colorWithWhite:0.10 alpha:1.0];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 58.0;

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = RXAABackground();
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: RXAAGreen()};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = RXAAGreen();
}

- (void)closeMenu {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        gMenuNav = nil;
        RAACHEATRestorePreviousKeyWindow();
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed || self.navigationController.isBeingDismissed) {
        gMenuNav = nil;
        RAACHEATRestorePreviousKeyWindow();
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return (NSInteger)[RXAAFeatureTitles() count];
    }
    return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"FEATURES" : @"TOOLS";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"UI-only demo switches. They save ON/OFF locally and do not hook or modify any game.";
    }
    return @"Rxaa UI Debug Menu | Telegram: @kun_amra\nGet Code opens the offline catalog. Python Engine provides terminal CLI & config generation.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"RXAACell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithWhite:0.04 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    }

    if (indexPath.section == 0) {
        NSArray<NSString *> *titles = RXAAFeatureTitles();
        NSArray<NSString *> *keys = RXAAFeatureKeys();
        BOOL on = [[NSUserDefaults standardUserDefaults] boolForKey:keys[(NSUInteger)indexPath.row]];

        cell.textLabel.text = titles[(NSUInteger)indexPath.row];
        cell.detailTextLabel.text = on ? @"ON - UI demo" : @"OFF - UI demo";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;

        UISwitch *sw = [[UISwitch alloc] init];
        sw.onTintColor = RXAAGreen();
        sw.tag = indexPath.row;
        sw.on = on;
        [sw addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryView = nil;
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Get Code";
            cell.detailTextLabel.text = @"Browse menu names, addresses and ARM64 xrefs";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [NSString stringWithFormat:@"All Features (%lu)",
                                   (unsigned long)[RXAACatalogFeatures() count]];
            cell.detailTextLabel.text = @"Browse every catalog feature entry";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Apply All (Demo)";
            cell.detailTextLabel.text = @"Turn all demo switches ON";
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Reset All (Demo)";
            cell.detailTextLabel.text = @"Turn all demo switches OFF";
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 4) {
            cell.textLabel.text = @"Python Engine (mod_menu.py)";
            cell.detailTextLabel.text = @"CLI & Config Generator in Application Support";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = @"Telegram: @kun_amra";
            cell.detailTextLabel.text = @"Tap to open official Telegram channel";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    return cell;
}

- (void)toggleChanged:(UISwitch *)sender {
    NSArray<NSString *> *keys = RXAAFeatureKeys();
    if (sender.tag < 0 || sender.tag >= (NSInteger)keys.count) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:keys[(NSUInteger)sender.tag]];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = sender.isOn ? @"ON - UI demo" : @"OFF - UI demo";
}

- (void)setAllDemoSwitches:(BOOL)on {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *key in RXAAFeatureKeys()) {
        [defaults setBool:on forKey:key];
    }
    for (NSDictionary *item in RXAACatalogFeatures()) {
        if (RXAACatalogFeatureIsActionable(item)) {
            [defaults setBool:on forKey:RXAACatalogFeatureKey(item)];
        }
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            RXAACatalogViewController *catalog = [[RXAACatalogViewController alloc] init];
            [self.navigationController pushViewController:catalog animated:YES];
        } else if (indexPath.row == 1) {
            RXAACatalogFeatureViewController *features = [[RXAACatalogFeatureViewController alloc] init];
            [self.navigationController pushViewController:features animated:YES];
        } else if (indexPath.row == 2 || indexPath.row == 3) {
            [self setAllDemoSwitches:(indexPath.row == 2)];
        } else if (indexPath.row == 4) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rxa Python Engine"
                message:@"mod_menu.py is bundled in your tweak Application Support directory.\n\nTo run on iOS:\n1. Open Terminal (NewTerm or SSH)\n2. Type 'rxa-menu'\n   (or python3 mod_menu.py --cli)\n\nSupports full interactive CLI, preset loading, and config file generation."
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else if (indexPath.row == 5) {
            NSURL *url = [NSURL URLWithString:@"https://t.me/kun_amra"];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation RXAACatalogSwitch
@end

@implementation RXAACatalogFeatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"All Features";
    self.tableView.backgroundColor = RXAABackground();
    self.tableView.separatorColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 58.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[RXAACatalogCategories() count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray<NSString *> *categories = RXAACatalogCategories();
    if (section < 0 || section >= (NSInteger)categories.count) {
        return 0;
    }
    return (NSInteger)[RXAACatalogFeaturesForCategory(categories[(NSUInteger)section]) count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray<NSString *> *categories = RXAACatalogCategories();
    if (section < 0 || section >= (NSInteger)categories.count) {
        return nil;
    }
    return [categories[(NSUInteger)section] uppercaseString];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"UI-only demo entries. Switches save locally; no game hooks or memory access.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"RXAACatalogFeatureCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.07 green:0.10 blue:0.14 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.72;
    }

    NSArray<NSString *> *categories = RXAACatalogCategories();
    if (indexPath.section < 0 || indexPath.section >= (NSInteger)categories.count) {
        return cell;
    }
    NSArray<NSDictionary *> *features = RXAACatalogFeaturesForCategory(categories[(NSUInteger)indexPath.section]);
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)features.count) {
        return cell;
    }
    NSDictionary *item = features[(NSUInteger)indexPath.row];

    NSString *label = item[@"label"];
    NSString *category = item[@"category"];
    NSString *kind = item[@"kind"];
    cell.textLabel.text = label ? label : @"(unnamed)";
    category = category ? category : @"feature";
    kind = kind ? kind : @"entry";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ - UI demo", category, kind];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (RXAACatalogFeatureIsActionable(item)) {
        RXAACatalogSwitch *sw = [[RXAACatalogSwitch alloc] init];
        sw.featureKey = RXAACatalogFeatureKey(item);
        sw.onTintColor = RXAAGreen();
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:sw.featureKey];
        sw.accessibilityLabel = item[@"label"];
        [sw addTarget:self action:@selector(catalogSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ - catalog entry", category, kind];
    }
    return cell;
}

- (void)catalogSwitchChanged:(UISwitch *)sender {
    if (![sender isKindOfClass:[RXAACatalogSwitch class]]) {
        return;
    }
    RXAACatalogSwitch *sw = (RXAACatalogSwitch *)sender;
    if (!sw.featureKey) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:sw.isOn forKey:sw.featureKey];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation RXAACatalogViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Code Catalog";
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Close"
                style:UIBarButtonItemStyleDone
               target:self
               action:@selector(closeMenu)];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor blackColor];
    self.webView.scrollView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.webView];

    NSURL *url = [NSURL fileURLWithPath:RAACHEATCatalogPath()];
    [self.webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

- (void)closeMenu {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        gMenuNav = nil;
        RAACHEATRestorePreviousKeyWindow();
    }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

static UIWindowScene *RAACHEATActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        UIApplication *app = [UIApplication sharedApplication];
        UIWindowScene *fallback = nil;
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                return windowScene;
            }
            if (!fallback && windowScene.activationState != UISceneActivationStateUnattached) {
                fallback = windowScene;
            }
        }
        if (fallback) {
            return fallback;
        }
        for (UIWindow *window in app.windows) {
            if (window.windowScene) {
                return window.windowScene;
            }
        }
    }
    return nil;
}

static UIWindow *RAACHEATHostWindow(UIWindowScene *scene) {
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *keyWindow = RAACHEATKeyWindowForScene(scene);
    if (keyWindow && keyWindow != gOverlayWindow && keyWindow != gButtonWindow) {
        return keyWindow;
    }
    if (scene) {
        UIWindow *fallback = nil;
        for (UIWindow *window in scene.windows) {
            if (window == gOverlayWindow || window == gButtonWindow) {
                continue;
            }
            if (!window.hidden) {
                return window;
            }
            if (!fallback) {
                fallback = window;
            }
        }
        if (fallback) {
            return fallback;
        }
    }
    for (UIWindow *window in app.windows) {
        if (window != gOverlayWindow && window != gButtonWindow) {
            return window;
        }
    }
    return nil;
}

static void RAACHEATInstallOpenGesture(RAACHEATRootController *root, UIWindowScene *scene) {
    UIWindow *host = RAACHEATHostWindow(scene);
    if (!host || !root) {
        return;
    }
    if (gOpenGesture && gGestureWindow == host &&
        [host.gestureRecognizers containsObject:gOpenGesture]) {
        return;
    }
    if (gOpenGesture && gGestureWindow) {
        [gGestureWindow removeGestureRecognizer:gOpenGesture];
    }
    gOpenGesture = [[UITapGestureRecognizer alloc] initWithTarget:root action:@selector(raacheatOpen)];
    gOpenGesture.numberOfTouchesRequired = 4;
    gOpenGesture.numberOfTapsRequired = 3;
    gOpenGesture.cancelsTouchesInView = NO;
    gOpenGesture.delaysTouchesBegan = NO;
    gOpenGesture.delegate = root;
    [host addGestureRecognizer:gOpenGesture];
    gGestureWindow = host;
    NSLog(@"[Rxaa] fallback gesture installed on %@", host);
}

static void RAACHEATAttachWindowToScene(void) {
    if (!gOverlayWindow) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = RAACHEATActiveWindowScene();
        if (!scene) {
            return;
        }
        if (gOverlayWindow.windowScene != scene) {
            gOverlayWindow.windowScene = scene;
        }
        if (gButtonWindow.windowScene != scene) {
            gButtonWindow.windowScene = scene;
        }
        CGRect bounds = scene.coordinateSpace.bounds;
        if (!CGRectIsEmpty(bounds)) {
            gOverlayWindow.frame = bounds;
        }
        UIViewController *root = gOverlayWindow.rootViewController;
        root.view.frame = gOverlayWindow.bounds;
        RAACHEATInstallOpenGesture((RAACHEATRootController *)root, scene);
    }

    gOverlayWindow.windowLevel = UIWindowLevelAlert + 100.0;
    if (gButtonWindow) {
        gButtonWindow.windowLevel = UIWindowLevelAlert + 101.0;
        if (gMenuNav) {
            gOverlayWindow.hidden = NO;
            gButtonWindow.hidden = YES;
        } else {
            gOverlayWindow.hidden = YES;
            gButtonWindow.hidden = NO;
            RAACHEATRestoreFloatButtonPosition();
        }
    }
}

static void RAACHEATEnsureOverlayVisible(void) {
    if (!gOverlayWindow) {
        return;
    }

    RAACHEATAttachWindowToScene();

    if (gMenuNav) {
        gOverlayWindow.hidden = NO;
        if (gButtonWindow) {
            gButtonWindow.hidden = YES;
        }
        [gOverlayWindow makeKeyAndVisible];
    } else {
        gOverlayWindow.hidden = YES;
        if (gButtonWindow) {
            gButtonWindow.hidden = NO;
        }
    }
}

static void RAACHEATInstallOverlay(void) {
    if (gOverlayWindow || gInstallAttempts++ > 40) {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if (!app) {
        return;
    }

    UIWindowScene *scene = nil;
    if (@available(iOS 13.0, *)) {
        scene = RAACHEATActiveWindowScene();
        if (scene) {
            gOverlayWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else if (app.windows.count > 0) {
            // Older/legacy apps can have windows without adopting UIScene.
            NSLog(@"[Rxaa] no UIWindowScene; using legacy window fallback");
            gOverlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        } else {
            NSLog(@"[Rxaa] waiting for active UIWindowScene");
            return;
        }
    } else {
        gOverlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    CGRect bounds = scene ? scene.coordinateSpace.bounds : [UIScreen mainScreen].bounds;
    if (CGRectIsEmpty(bounds)) {
        bounds = [UIScreen mainScreen].bounds;
    }

    gOverlayWindow.frame = bounds;
    gOverlayWindow.windowLevel = UIWindowLevelAlert + 100.0;
    gOverlayWindow.backgroundColor = [UIColor clearColor];
    gOverlayWindow.rootViewController = [[RAACHEATRootController alloc] init];
    gOverlayWindow.hidden = YES;

    RAACHEATRootController *root = (RAACHEATRootController *)gOverlayWindow.rootViewController;
    root.view.frame = bounds;

    gFloatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    gFloatButton.frame = CGRectMake(0.0, 0.0,
                                    kRXAAFloatButtonSize, kRXAAFloatButtonSize);
    gFloatButton.autoresizingMask = UIViewAutoresizingNone;
    gFloatButton.backgroundColor = [UIColor colorWithRed:0.06 green:0.13 blue:0.10 alpha:0.94];
    gFloatButton.layer.cornerRadius = kRXAAFloatButtonSize * 0.5;
    gFloatButton.layer.borderWidth = 1.0;
    gFloatButton.layer.borderColor = [UIColor colorWithRed:0.31 green:0.94 blue:0.65 alpha:0.85].CGColor;
    gFloatButton.clipsToBounds = YES;
    gFloatButton.accessibilityLabel = @"Rxaa";

    NSString *iconPath = RAACHEATResourcePath(@"menu_icon.png");
    if (!iconPath) {
        iconPath = RAACHEATResourcePath(@"menu_image.jpg");
    }
    UIImage *icon = iconPath ? [UIImage imageWithContentsOfFile:iconPath] : nil;
    if (icon) {
        [gFloatButton setBackgroundImage:icon forState:UIControlStateNormal];
    } else {
        [gFloatButton setTitle:@"R" forState:UIControlStateNormal];
        [gFloatButton setTitleColor:RXAAGreen() forState:UIControlStateNormal];
        gFloatButton.titleLabel.font = [UIFont monospacedSystemFontOfSize:22 weight:UIFontWeightBold];
    }

    RAACHEATButtonController *buttonRoot = [[RAACHEATButtonController alloc] init];
    if (@available(iOS 13.0, *)) {
        if (scene) {
            gButtonWindow = [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
    if (!gButtonWindow) {
        gButtonWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                                   kRXAAFloatButtonSize,
                                                                   kRXAAFloatButtonSize)];
    }
    gButtonWindow.frame = CGRectMake(0.0, 0.0,
                                     kRXAAFloatButtonSize, kRXAAFloatButtonSize);
    gButtonWindow.windowLevel = UIWindowLevelAlert + 101.0;
    gButtonWindow.backgroundColor = [UIColor clearColor];
    gButtonWindow.rootViewController = buttonRoot;
    gButtonWindow.hidden = NO;
    gFloatButton.frame = buttonRoot.view.bounds;
    [buttonRoot.view addSubview:gFloatButton];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:buttonRoot action:@selector(raacheatPan:)];
    pan.cancelsTouchesInView = YES;
    pan.maximumNumberOfTouches = 1;
    [gFloatButton addGestureRecognizer:pan];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:buttonRoot action:@selector(raacheatOpen)];
    tap.numberOfTapsRequired = 1;
    tap.cancelsTouchesInView = NO;
    [gFloatButton addGestureRecognizer:tap];

    RAACHEATRestoreFloatButtonPosition();
    RAACHEATInstallOpenGesture(root, scene);
    NSLog(@"[Rxaa] overlay installed scene=%@ bounds=%@", scene, NSStringFromCGRect(bounds));
}

static void RAACHEATTryInstall(void) {
    if (gOverlayWindow) {
        RAACHEATAttachWindowToScene();
        if (@available(iOS 13.0, *)) {
            if (!gOverlayWindow.windowScene && gInstallAttempts <= 40) {
                gInstallAttempts++;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    RAACHEATTryInstall();
                });
            }
        }
        return;
    }
    RAACHEATInstallOverlay();
    if (!gOverlayWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RAACHEATTryInstall();
        });
    }
}

static void RAACHEATObserveLifecycle(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        id activationToken = [center addObserverForName:UIApplicationDidBecomeActiveNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification *note) {
            gInstallAttempts = 0;
            if (gOverlayWindow) {
                RAACHEATEnsureOverlayVisible();
            } else {
                RAACHEATTryInstall();
            }
        }];
        (void)activationToken;

        if (@available(iOS 13.0, *)) {
            id sceneToken = [center addObserverForName:UISceneDidActivateNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification *note) {
                gInstallAttempts = 0;
                if (gOverlayWindow) {
                    RAACHEATEnsureOverlayVisible();
                } else {
                    RAACHEATTryInstall();
                }
            }];
            (void)sceneToken;
        }

        id keyToken = [center addObserverForName:UIWindowDidBecomeKeyNotification
                                          object:nil
                                           queue:[NSOperationQueue mainQueue]
                                      usingBlock:^(NSNotification *note) {
            if (!gOverlayWindow) {
                return;
            }
            if ([note.object isKindOfClass:[UIWindow class]] &&
                (note.object == gOverlayWindow || note.object == gButtonWindow)) {
                return;
            }
            RAACHEATEnsureOverlayVisible();
        }];
        (void)keyToken;

        id visibleToken = [center addObserverForName:UIWindowDidBecomeVisibleNotification
                                              object:nil
                                               queue:[NSOperationQueue mainQueue]
                                          usingBlock:^(NSNotification *note) {
            if (!gOverlayWindow) {
                return;
            }
            if ([note.object isKindOfClass:[UIWindow class]] &&
                (note.object == gOverlayWindow || note.object == gButtonWindow)) {
                return;
            }
            RAACHEATEnsureOverlayVisible();
        }];
        (void)visibleToken;

        id orientationToken = [center addObserverForName:UIDeviceOrientationDidChangeNotification
                                                  object:nil
                                                   queue:[NSOperationQueue mainQueue]
                                              usingBlock:^(NSNotification *note) {
            (void)note;
            if (gOverlayWindow) {
                RAACHEATEnsureOverlayVisible();
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (gOverlayWindow) {
                        RAACHEATEnsureOverlayVisible();
                    }
                });
            }
        }];
        (void)orientationToken;
    });
}

%ctor {
    @autoreleasepool {
        RAACHEATObserveLifecycle();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RAACHEATTryInstall();
        });
    }
}
