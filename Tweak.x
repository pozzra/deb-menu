#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Rxaa is a UI-only debug overlay. It intentionally contains no game hooks,
// memory access, aimbot, ESP, or offset code.

static UIWindow *gOverlayWindow = nil;
static UIButton *gFloatButton = nil;
static UINavigationController *gMenuNav = nil;
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

@interface RXAAMenuViewController : UITableViewController
@end

@interface RXAACatalogViewController : UIViewController
@property (nonatomic, strong) WKWebView *webView;
@end

@interface RAACHEATRootController : UIViewController
- (void)raacheatOpen;
- (void)raacheatPan:(UIPanGestureRecognizer *)pan;
@end

static void RAACHEATOpenPanel(void) {
    if (!gOverlayWindow || gMenuNav) {
        return;
    }

    UIViewController *root = gOverlayWindow.rootViewController;
    if (!root || root.presentedViewController) {
        return;
    }

    RXAAMenuViewController *menu = [[RXAAMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
    gMenuNav = [[UINavigationController alloc] initWithRootViewController:menu];
    gMenuNav.modalPresentationStyle = UIModalPresentationFullScreen;
    [root presentViewController:gMenuNav animated:YES completion:nil];
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
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return (NSInteger)[RXAAFeatureTitles() count];
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"FEATURES" : @"TOOLS";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"UI-only demo switches. They save ON/OFF locally and do not hook or modify any game.";
    }
    return nil;
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
        cell.textLabel.text = @"Code Catalog";
        cell.detailTextLabel.text = @"Browse menu names, addresses and ARM64 xrefs";
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        RXAACatalogViewController *catalog = [[RXAACatalogViewController alloc] init];
        [self.navigationController pushViewController:catalog animated:YES];
    }
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
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
