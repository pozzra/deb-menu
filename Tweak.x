#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Rxaa is a UI-only debug overlay. It intentionally contains no game hooks,
// memory access, aimbot, ESP, or offset code.

static UIWindow *gOverlayWindow = nil;
static UIButton *gFloatButton = nil;
static UINavigationController *gMenuNav = nil;
static UITapGestureRecognizer *gOpenGesture = nil;
static UIWindow *gGestureWindow = nil;
static UIWindow *gPreviousKeyWindow = nil;
static int gInstallAttempts = 0;

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
    return [UIColor colorWithRed:0.04 green:0.07 blue:0.10 alpha:1.0];
}

static NSString *RAACHEATResourcePath(NSString *name) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *bases = @[
        @"/var/jb/Library/Application Support/RAACHEATMenuDebug",
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

static void RAACHEATRestorePreviousKeyWindow(void) {
    if (gPreviousKeyWindow && gPreviousKeyWindow != gOverlayWindow) {
        [gPreviousKeyWindow makeKeyWindow];
    }
    gPreviousKeyWindow = nil;
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
    gPreviousKeyWindow = RAACHEATKeyWindowForScene(nil);
    if (gPreviousKeyWindow == gOverlayWindow) {
        gPreviousKeyWindow = nil;
    }
    if (!gPreviousKeyWindow) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window != gOverlayWindow) {
                gPreviousKeyWindow = window;
                break;
            }
        }
    }
    [gOverlayWindow makeKeyAndVisible];

    RXAAMenuViewController *menu = [[RXAAMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:menu];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
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

- (void)raacheatOpen {
    RAACHEATOpenPanel();
}

- (void)raacheatPan:(UIPanGestureRecognizer *)pan {
    UIView *view = pan.view;
    CGPoint translation = [pan translationInView:view.superview];
    view.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:view.superview];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
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
    self.tableView.separatorColor = [UIColor colorWithWhite:0.16 alpha:1.0];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return (NSInteger)[RXAAFeatureTitles() count];
    }
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"FEATURES" : @"TOOLS";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"UI-only demo switches. They save ON/OFF locally and do not hook or modify any game.";
    }
    return @"Get Code opens the offline catalog. All Features lists the catalog entries. Apply All / Reset All only change demo switch states.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"RXAACell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.07 green:0.10 blue:0.14 alpha:1.0];
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
        } else {
            cell.textLabel.text = @"Reset All (Demo)";
            cell.detailTextLabel.text = @"Turn all demo switches OFF";
            cell.accessoryType = UITableViewCellAccessoryNone;
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
        } else {
            [self setAllDemoSwitches:(indexPath.row == 2)];
        }
    }
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
    if (keyWindow && keyWindow != gOverlayWindow) {
        return keyWindow;
    }
    if (scene) {
        UIWindow *fallback = nil;
        for (UIWindow *window in scene.windows) {
            if (window == gOverlayWindow) {
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
        if (window != gOverlayWindow) {
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
        CGRect bounds = scene.coordinateSpace.bounds;
        if (!CGRectIsEmpty(bounds)) {
            gOverlayWindow.frame = bounds;
        }
        gOverlayWindow.hidden = NO;
        UIViewController *root = gOverlayWindow.rootViewController;
        root.view.frame = gOverlayWindow.bounds;
        RAACHEATInstallOpenGesture((RAACHEATRootController *)root, scene);
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
    gOverlayWindow.windowLevel = UIWindowLevelAlert + 10.0;
    gOverlayWindow.backgroundColor = [UIColor clearColor];
    gOverlayWindow.rootViewController = [[RAACHEATRootController alloc] init];
    gOverlayWindow.hidden = NO;

    RAACHEATRootController *root = (RAACHEATRootController *)gOverlayWindow.rootViewController;
    root.view.frame = bounds;

    gFloatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    gFloatButton.frame = CGRectMake(bounds.size.width - 66, 96, 52, 52);
    gFloatButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    gFloatButton.backgroundColor = [UIColor colorWithRed:0.06 green:0.13 blue:0.10 alpha:0.94];
    gFloatButton.layer.cornerRadius = 26.0;
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
    [gFloatButton addTarget:root action:@selector(raacheatOpen) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:root action:@selector(raacheatPan:)];
    pan.cancelsTouchesInView = NO;
    [gFloatButton addGestureRecognizer:pan];

    [root.view addSubview:gFloatButton];
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
                RAACHEATAttachWindowToScene();
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
                    RAACHEATAttachWindowToScene();
                } else {
                    RAACHEATTryInstall();
                }
            }];
            (void)sceneToken;
        }
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
