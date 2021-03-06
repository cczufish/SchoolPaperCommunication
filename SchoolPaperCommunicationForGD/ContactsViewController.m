//
//  ContactsViewController.m
//  SchoolPaperCommunicationForGD
//
//  Created by yaodd on 13-11-29.
//  Copyright (c) 2013年 yaodd. All rights reserved.
//

#import "ContactsViewController.h"
#import "ChatViewController.h"
#import "XXTUserRole.h"
#import "XXTModelGlobal.h"
#import "Dao.h"
#import "UIImageView+category.h"
#import "SendMessageViewController.h"

#define CONTACT_VIEW_TAG    111111

@interface ContactsViewController ()
{
    CGFloat tableViewY;
    NSMutableArray *data;
    XXTModelGlobal *modelGlobal;
    XXTUserRole *userRole;
    BOOL isSearching;
}
@property(nonatomic, strong) UISearchDisplayController *strongSearchDisplayController; // UIViewController doesn't retain the search display controller if it's created programmatically: http://openradar.appspot.com/10254897
@property(nonatomic, copy) NSArray *famousPersons;
@property(nonatomic, copy) NSArray *filteredPersons;
@property(nonatomic, copy) NSArray *sections;

@end

@implementation ContactsViewController
@synthesize contactsTableView;
@synthesize searchBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    tableViewY = 0;
    if (IOS_VERSION_7_OR_ABOVE)
    {
        // OS version >= 7.0
//        self.edgesForExtendedLayout = UIRectEdgeNone;
        tableViewY = 0;
        
    }else{
        tableViewY = 49;
    }
    [self initLayout];
    [self initData];
//    [self.contactsTableView reloadData];
}
//初始化tableView
- (void)initLayout{
//    self.title = @"通讯录";
    isSearching = NO;
    self.contactsTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - tableViewY - TOP_BAR_HEIGHT)];
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:self.contactsTableView];
    
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectZero];
    self.searchBar.placeholder = @"Search";
    self.searchBar.delegate = self;
    
    [self.searchBar sizeToFit];
    
    self.strongSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    
    self.contactsTableView.tableHeaderView = self.searchBar;
    self.contactsTableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchBar.bounds));
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"sync"] style:UIBarButtonItemStyleBordered target:self action:@selector(refreshAction:)];
    
    self.navigationItem.rightBarButtonItem = refreshButton;
}

//初始化数据加载
- (void)initData{
    
    modelGlobal = [XXTModelGlobal sharedModel];
    userRole = modelGlobal.currentUser;
    if ([userRole.contactGroupArr count] == 0) {
        NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(downloadContactGroup:) object:nil];
        [thread start];

    }
    
    [self updateContactGroup];
}
//下载通讯录
- (void)downloadContactGroup:(NSThread *)thread{
    Dao *dao = [Dao sharedDao];
    NSInteger isSuccess = [dao requestForGetContactList];
    if (isSuccess ==  1) {
        [self performSelectorOnMainThread:@selector(updateContactGroup) withObject:nil waitUntilDone:YES];
    }

}
//更新通讯录
- (void)updateContactGroup{
    isSearching = NO;
    modelGlobal = [XXTModelGlobal sharedModel];
    userRole = modelGlobal.currentUser;
    data = [[NSMutableArray alloc]init];

    for (XXTGroup *group in userRole.contactGroupArr) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:group.groupName forKey:@"groupname"];
        NSLog(@"groupname %@",group.groupName);
        NSArray *groupMemberArr = group.groupMemberArr;
        [dict setObject:groupMemberArr forKey:@"users"];
//        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"expanded"];
        [data addObject:dict];
    }
    [contactsTableView reloadData];
}
//刷新按钮响应事件
- (void)refreshAction:(id)sender
{
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(downloadContactGroup:) object:nil];
    [thread start];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (animated) {
//        [self.contactsTableView flashScrollIndicators];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        [self setEdgesForExtendedLayout:UIRectEdgeBottom];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma UITableViewDelegate mark -

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if ([title isEqualToString:UITableViewIndexSearch]) {
        [self scrollTableViewToSearchBarAnimated:NO];
        return NSNotFound;
    } else {
        return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index] - 1; // -1 because we add the search symbol
    }
}

- (void)scrollTableViewToSearchBarAnimated:(BOOL)animated
{
//    NSAssert(YES, @"This method should be handled by a subclass!");
    [self.contactsTableView scrollRectToVisible:self.searchBar.frame animated:animated];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [data count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int num = 0;
    if (![self isExpanded:section]) {
        num = 0;
    } else{
        NSDictionary * d = [data objectAtIndex:section];
        num = [[d objectForKey:@"users"] count];
        
    }
    return num;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 66;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        ContactView *contactView = [[ContactView alloc]initWithFrame:CGRectMake(0, 0, cell.frame.size.width, 66)];
        [contactView setTag:CONTACT_VIEW_TAG];
        contactView.delegate = self;
        [cell addSubview:contactView];
    }
    ContactView *contactView = (ContactView *)[cell viewWithTag:CONTACT_VIEW_TAG];
    NSDictionary* item= (NSDictionary*)[data objectAtIndex: indexPath.section];
	NSArray *users = (NSArray*)[item objectForKey:@"users"];
    
	if (users == nil) {
        NSLog(@"nil");
		return cell;
	}
	//加载数据
    XXTContactPerson *user = [users objectAtIndex:indexPath.row];
    [contactView setData:user];
	[cell setBackgroundColor:[UIColor whiteColor]];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (isSearching) {
        return 0;
    }
    return  44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    ContactView *contactView = (ContactView *)[cell viewWithTag:CONTACT_VIEW_TAG];
    [self jumpToChatWithPerson:contactView.contactPerson];
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
{
	
    
	UIView *hView;
	if (UIInterfaceOrientationLandscapeRight == [[UIDevice currentDevice] orientation] ||
        UIInterfaceOrientationLandscapeLeft == [[UIDevice currentDevice] orientation])
	{
		hView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 480, 44)];
	}
	else
	{
		hView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
        //self.tableView.tableHeaderView.frame = CGRectMake(0.f, 0.f, 320.f, 44.f);
	}
    //UIView *hView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    
	UIButton* eButton = [[UIButton alloc] init];
    
	//按钮填充整个视图
	eButton.frame = hView.frame;
	[eButton addTarget:self action:@selector(expandButtonClicked:)
      forControlEvents:UIControlEventTouchUpInside];
	eButton.tag = section;//把节号保存到按钮tag，以便传递到expandButtonClicked方法
    
	//根据是否展开，切换按钮显示图片
	if ([self isExpanded:section]){
		[eButton setImage: [ UIImage imageNamed:@"arrow_open"] forState:UIControlStateNormal];
        [eButton setTitleEdgeInsets:UIEdgeInsetsMake(6, 45.5, 0, 0)];

    }
	else{
		[eButton setImage: [ UIImage imageNamed:@"arrow_close"] forState:UIControlStateNormal];
        [eButton setTitleEdgeInsets:UIEdgeInsetsMake(6, 50, 0, 0)];

    }
    
	//由于按钮的标题，
	//4个参数是上边界，左边界，下边界，右边界。
	eButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	[eButton setImageEdgeInsets:UIEdgeInsetsMake(5, 20, 0, 0)];
    
    
	//设置按钮显示颜色
	eButton.backgroundColor = [UIColor lightGrayColor];
	[eButton setTitle:[[data objectAtIndex:section] objectForKey:@"groupname"] forState:UIControlStateNormal];
	[eButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [eButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    //[eButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[eButton setBackgroundColor:[UIColor whiteColor]];
//	[eButton setBackgroundImage: [UIImage imageNamed: @"btn_listbg.png" ] forState:UIControlStateNormal];//btn_line.png"
	//[eButton setTitleShadowColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
	//[eButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    
	[hView addSubview: eButton];
    
    UIView *sepector = [[UIView alloc]initWithFrame:CGRectMake(0, 43, hView.frame.size.width, 1)];
    [sepector setBackgroundColor:[UIColor colorWithRed:213.0/255 green:213.0/255 blue:213.0/255 alpha:1.0]];
    
    [hView addSubview:sepector];
//    [hView setHidden:YES];
	return hView;
//    return nil;
    
}


//对指定的节进行“展开/折叠”操作
-(void)collapseOrExpand:(int)section{
	Boolean expanded = NO;
	//Boolean searched = NO;
	NSMutableDictionary* d=[data objectAtIndex:section];
	
	//若本节model中的“expanded”属性不为空，则取出来
	if([d objectForKey:@"expanded"]!=nil)
		expanded=[[d objectForKey:@"expanded"]intValue];
	
	//若原来是折叠的则展开，若原来是展开的则折叠
	[d setObject:[NSNumber numberWithBool:!expanded] forKey:@"expanded"];
    
}


//返回指定节的“expanded”值
-(Boolean)isExpanded:(int)section{
	Boolean expanded = NO;
	NSMutableDictionary* d=[data objectAtIndex:section];
	
	//若本节model中的“expanded”属性不为空，则取出来
	if([d objectForKey:@"expanded"]!=nil)
		expanded=[[d objectForKey:@"expanded"]intValue];
	
	return expanded;
}


//按钮被点击时触发
-(void)expandButtonClicked:(id)sender{
	
	UIButton* btn= (UIButton*)sender;
	NSInteger section= btn.tag; //取得tag知道点击对应哪个块
	
	//	NSLog(@"click %d", section);
	[self collapseOrExpand:section];
	
	//刷新tableview
	[contactsTableView reloadData];
	
}

#pragma mark - Search Delegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.filteredPersons = self.famousPersons;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.filteredPersons = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.filteredPersons = [self.filteredPersons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchString]];
    
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//    if ([[segue identifier] isEqualToString:@"JumpToChat"]) {
    NSLog(@"ssss");
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
//    }x
}
#pragma contactViewDelegate mark -
- (void)ContactViewButtonAction:(ContactView *)contactView button:(UIButton *)button person:(XXTContactPerson *)person{
    [self.searchBar resignFirstResponder];
    if (button.tag == 0) {
        NSLog(@"打电话");
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://10086"]];
        UIWebView*callWebview =[[UIWebView alloc] init];
        NSURL *telURL =[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",contactView.phoneLabel.text]];// 貌似tel:// 或者 tel: 都行
        [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
        //记得添加到view上
        [self.view addSubview:callWebview];

    }
    if (button.tag == 1) {
        NSLog(@"发短信");
        [self jumpToMessageWithPerson:person];
    }
    if (button.tag == 2) {
        NSLog(@"即时聊天");
        [self jumpToChatWithPerson:person];
    }
}
//跳转到发短信页面
- (void)jumpToMessageWithPerson:(XXTContactPerson *)person{
    self.hidesBottomBarWhenPushed = YES;
    SendMessageViewController *sendMessageViewController = [[SendMessageViewController alloc]initWithNibName:@"SendMessageViewController" bundle:nil];
    [sendMessageViewController setCurrentPid:person.pid];
    [self.navigationController pushViewController:sendMessageViewController animated:YES];
    self.hidesBottomBarWhenPushed = NO;
    
}
//跳转到聊天界面
- (void)jumpToChatWithPerson:(XXTContactPerson *)person{
    [self.searchBar resignFirstResponder];
    self.hidesBottomBarWhenPushed = YES;
    ChatViewController *chatViewController = [[ChatViewController alloc]init];
    [chatViewController setCurrentPid:person.pid];
    [self.navigationController pushViewController:chatViewController animated:YES];
    self.hidesBottomBarWhenPushed = NO;
    
}
#pragma UISearchBarDelegate mark
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    isSearching = YES;
    data = [[NSMutableArray alloc]init];
    for (XXTGroup *group in userRole.contactGroupArr) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:group.groupName forKey:@"groupname"];
        NSLog(@"groupname %@",group.groupName);
        NSMutableArray *groupMemberArr = [[NSMutableArray alloc]init];
        for (XXTContactPerson *person in group.groupMemberArr) {
            if ([self isMatchWithSeatchText:searchText originalText:person.name] || [self isMatchWithSeatchText:searchText originalText:person.phone]) {
                [groupMemberArr addObject:person];
            }
        }
        [dict setObject:groupMemberArr forKey:@"users"];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"expanded"];
        [data addObject:dict];
    }
    if (searchText.length == 0) {
        isSearching = NO;
    }
    [contactsTableView reloadData];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self updateContactGroup];
}
//字符串匹配搜索算法
- (BOOL)isMatchWithSeatchText:(NSString *)searchText originalText:(NSString *)originalText{
    BOOL result = YES;
    int start = 0;
    for (int i = 0; i < searchText.length; i ++) {
        unichar c = [searchText characterAtIndex:i];
        for (int k = start; k < originalText.length; k ++) {
            if (c == [originalText characterAtIndex:k]) {
                start = k + 1;
                break;
            }
            if (k == originalText.length - 1) {
                result = NO;
            }
        }
    }
    
    return result;
}


@end
