//
//  ViewController.m
//  runtime
//
//  Created by 吴文鹏 on 2017/11/17.
//  Copyright © 2017年 DocIn. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "secondViewContrllerViewController.h"

static char mykey;

@interface ViewController ()

{
    BOOL hhhh;
    
    int  llll;
}

@property (nonatomic,copy) NSString *name;

@property (nonatomic,assign) BOOL isBoy;

@property (nonatomic,strong) secondViewContrllerViewController *secondCtr;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    unsigned int count;

    //所谓添加关联对象，实际上就是给累添加一个属性
    //添加关联对象的第一种方式，这种方式只需要传入value，你并不知道key是什么
    [self addAssociatedObject:@"吴文鹏"];
    NSLog(@"myname = %@", [self getAssociatedObject]);
    
    //添加关联对象的第二种方式，自己设定key和value
    [self addAssociatedObject_two:@"程丽丽"];
    //注:我们可以在外面去设定他，然后在里面去用它，参考wpsearchbar添加一个属性值
    
    //获取属性列表
    objc_property_t *propertylist = class_copyPropertyList([self class], &count);
    
    for (int i = 0; i < count; i++)
    {
        const char *propertyname = property_getName(propertylist[i]);
        NSLog(@"property----="">%@", [NSString stringWithUTF8String:propertyname]);
    }
    
    //获取方法列表
    Method *methodlist = class_copyMethodList([self class], &count);
    
    for (int i = 0; i < count; i++)
    {
        NSLog(@"method----="">%@", NSStringFromSelector(method_getName(methodlist[i])));
    }
    
    //获取成员变量列表
    Ivar *varlist = class_copyIvarList([self class], &count);
    
    for (int i = 0; i < count; i++)
    {
        const char *ivarname = ivar_getName(varlist[i]);
        
        NSLog(@"ivar----="">%@", [NSString stringWithUTF8String:ivarname]);
    }
    
    //获取协议列表(暂时没有获取到)
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList([self class], &count);
    for (int i = 0; i < count; i++)
    {
        const char *protocolname = protocol_getName(protocolList[i]);
        
        NSLog(@"protocol----="">%@", [NSString stringWithUTF8String:protocolname]);
    }
    
    //动态添加方法
    [self performSelector:@selector(nimabi:) withObject:@"参数"];
}

#pragma mark -
#pragma mark - 动态添加一个方法
#pragma mark -
void runAddMethod(id self, SEL _cmd, NSString *string)
{
    NSLog(@"add C IMP %@", string);
    
    //获取方法列表(看看有没有添加进去)
    unsigned int count;
    Method *methodlist = class_copyMethodList([self class], &count);
    
    for (int i = 0; i < count; i++)
    {
        NSLog(@"method----="">%@", NSStringFromSelector(method_getName(methodlist[i])));
    }
}
+ (BOOL)resolveInstanceMethod:(SEL)sel//做一个方法拦截
{
    //给本类动态添加一个方法
    if ([NSStringFromSelector(sel) isEqualToString:@"nimabi:"]) {
        class_addMethod(self, sel, (IMP)runAddMethod, "v@:*");
    }
    return YES;
}

#pragma mark -
#pragma mark - 消息转发流程
#pragma mark -
//1、动态方法解析
//接收到未知消息时（假设blackDog的walk方法尚未实现），runtime会调用+resolveInstanceMethod:（实例方法）或者+resolveClassMethod:（类方法）
//
//2、备用接收者
//如果以上方法没有做处理，runtime会调用- (id)forwardingTargetForSelector:(SEL)aSelector方法。
//如果该方法返回了一个非nil（也不能是self）的对象，而且该对象实现了这个方法，那么这个对象就成了消息的接收者，消息就被分发到该对象。
//适用情况：通常在对象内部使用，让内部的另外一个对象处理消息，在外面看起来就像是该对象处理了消息。
//比如：blackDog让女朋友whiteDog来接收这个消息
//
//3、完整消息转发
//在- (void)forwardInvocation:(NSInvocation *)anInvocation方法中选择转发消息的对象，其中anInvocation对象封装了未知消息的所有细节，并保留调用结果发送到原始调用者。
//比如：blackDog将消息完整转发給主人dogOwner来处理

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    //调用此方法的时候，需要将方法resolveInstanceMethod直接返回YES，不要再做动态添加的方法
    NSLog(@"进入消息转发");

    secondViewContrllerViewController *nima = [[secondViewContrllerViewController alloc] init];
    
    return nima;
}

#pragma mark -
#pragma mark - 系统常规方法
#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([[self getAssociatedObject_two] isEqualToString:@"程丽丽"])
    {
        self.view.backgroundColor = [UIColor redColor];
    }
}

#pragma mark -
#pragma mark - 方法交换
#pragma mark -
//load方法会在类第一次加载的时候被调用
//调用的时间比较靠前，适合在这个方法里做方法交换
+ (void)load{
    //方法交换应该被保证，在程序中只会执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //获得viewController的生命周期方法的selector
        SEL systemSel = @selector(viewWillAppear:);
        //自己实现的将要被交换的方法的selector
        SEL swizzSel = @selector(swiz_viewWillAppear:);
        //两个方法的Method
        Method systemMethod = class_getInstanceMethod([self class], systemSel);
        Method swizzMethod = class_getInstanceMethod([self class], swizzSel);
        //首先动态添加方法，实现是被交换的方法，返回值表示添加成功还是失败
        BOOL isAdd = class_addMethod(self, systemSel, method_getImplementation(swizzMethod), method_getTypeEncoding(swizzMethod));
        if (isAdd) {
            //如果成功，说明类中不存在这个方法的实现
            //将被交换方法的实现替换到这个并不存在的实现
            class_replaceMethod(self, swizzSel, method_getImplementation(systemMethod), method_getTypeEncoding(systemMethod));
        }else{
            //否则，交换两个方法的实现
            method_exchangeImplementations(systemMethod, swizzMethod);
        }
    });
}
- (void)swiz_viewWillAppear:(BOOL)animated{
    //这时候调用自己，看起来像是死循环
    //但是其实自己的实现已经被替换了
    NSLog(@"在viewWillAppear之前插入了一段代码");
    [self swiz_viewWillAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated{
    NSLog(@"其实这也算在viewWillAppear之前插入了一段代码，呵呵呵");
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
}

#pragma mark -
#pragma mark - 添加关联对象
#pragma mark -
//添加关联对象
- (void)addAssociatedObject:(id)object{
    objc_setAssociatedObject(self, @selector(getAssociatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
//获取关联对象
- (id)getAssociatedObject{
    return objc_getAssociatedObject(self, _cmd);
}

//添加关联对象的第二种方式
- (void)addAssociatedObject_two:(id)object{
    objc_setAssociatedObject(self, &mykey, object, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

//获取关联对象的第二种方式
- (id)getAssociatedObject_two{
    return objc_getAssociatedObject(self, &mykey);
}

#pragma mark -
#pragma mark - 字典转模型
#pragma mark -

//参考bookmetaInfo
+ (instancetype)modelWithDict:(NSDictionary *)dict{
    id model = [[self alloc] init];
    unsigned int count = 0;
    
    Ivar *ivars = class_copyIvarList(self, &count);
    for (int i = 0 ; i < count; i++) {
        Ivar ivar = ivars[i];
        
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        //这里注意，拿到的成员变量名为_hhhh,_llll
        ivarName = [ivarName substringFromIndex:1];
        id value = dict[ivarName];
        
        [model setValue:value forKeyPath:ivarName];
    }
    
    return model;
}

@end
