/****************************************************************************
 Copyright (c) 2014 Chukong Technologies Inc.
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "platform/CCPlatformConfig.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC

#include "UIWebViewImpl-osx.h"
#include "renderer/CCRenderer.h"
#include "base/CCDirector.h"
#include "platform/CCGLView.h"
#include "platform/mac/CCGL-mac.h"
#include "platform/CCFileUtils.h"
#include "ui/UIWebView.h"

#import <WebKit/WebKit.h>

@interface UIWebViewWrapper : NSObject
@property (nonatomic) std::function<bool(std::string url)> shouldStartLoading;
@property (nonatomic) std::function<void(std::string url)> didFinishLoading;
@property (nonatomic) std::function<void(std::string url)> didFailLoading;
@property (nonatomic) std::function<void(std::string url)> onJsCallback;

@property(nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property(nonatomic, readonly, getter=canGoForward) BOOL canGoForward;

+ (instancetype)webViewWrapper;

- (void)setVisible:(bool)visible;

- (void)setFrameWithX:(float)x y:(float)y width:(float)width height:(float)height;

- (void)setJavascriptInterfaceScheme:(const std::string &)scheme;

- (void)loadData:(const std::string &)data MIMEType:(const std::string &)MIMEType textEncodingName:(const std::string &)encodingName baseURL:(const std::string &)baseURL;

- (void)loadHTMLString:(const std::string &)string baseURL:(const std::string &)baseURL;

- (void)loadUrl:(const std::string &)urlString;

- (void)loadFile:(const std::string &)filePath;

- (void)stopLoading;

- (void)reload;

- (void)evaluateJS:(const std::string &)js;

- (void)goBack;

- (void)goForward;

- (void)setScalesPageToFit:(const bool)scalesPageToFit;
@end


@interface UIWebViewWrapper ()
@property(nonatomic, retain) WebView *uiWebView;
@property(nonatomic, copy) NSString *jsScheme;
@end

@implementation UIWebViewWrapper {
    
}

+ (instancetype)webViewWrapper {
    return [[[self alloc] init] autorelease];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uiWebView = nil;
        self.shouldStartLoading = nullptr;
        self.didFinishLoading = nullptr;
        self.didFailLoading = nullptr;
    }
    return self;
}

- (void)dealloc {
    //self.uiWebView.delegate = nil;
    [self.uiWebView removeFromSuperview];
    self.jsScheme = nil;
    [super dealloc];
}

- (void)setupWebView {
    if (!self.uiWebView) {
        self.uiWebView = [[[WebView alloc] init] autorelease];
        //self.uiWebView.delegate = self;
    }
    if (!self.uiWebView.superview) {
//        auto view = cocos2d::Director::getInstance()->getOpenGLView();
//        auto eaglview = (CCEAGLView *) view->getEAGLView();
//        [eaglview addSubview:self.uiWebView];
        auto view = cocos2d::Director::getInstance()->getOpenGLView();
        NSWindow *window = view->getCocoaWindow();
        [window.contentView addSubview:self.uiWebView];
        [self.uiWebView setWantsLayer:YES];
    }
}

- (void)setVisible:(bool)visible {
    self.uiWebView.hidden = !visible;
}

- (void)setFrameWithX:(float)x y:(float)y width:(float)width height:(float)height {
    if (!self.uiWebView) {[self setupWebView];}
    CGRect newFrame = CGRectMake(x, y, width, height);
    if (!CGRectEqualToRect(self.uiWebView.frame, newFrame)) {
        self.uiWebView.frame = CGRectMake(x, y, width, height);
    }
}

- (void)setJavascriptInterfaceScheme:(const std::string &)scheme {
    self.jsScheme = @(scheme.c_str());
}

- (void)loadData:(const std::string &)data MIMEType:(const std::string &)MIMEType textEncodingName:(const std::string &)encodingName baseURL:(const std::string &)baseURL {
    [[self.uiWebView mainFrame] loadData:[NSData dataWithBytes:data.c_str() length:data.length()]
                    MIMEType:@(MIMEType.c_str())
            textEncodingName:@(encodingName.c_str())
                     baseURL:[NSURL URLWithString:@(baseURL.c_str())]];
}

- (void)loadHTMLString:(const std::string &)string baseURL:(const std::string &)baseURL {
    [[self.uiWebView mainFrame] loadHTMLString:@(string.c_str()) baseURL:[NSURL URLWithString:@(baseURL.c_str())]];
}

- (void)loadUrl:(const std::string &)urlString {
    if (!self.uiWebView) {[self setupWebView];}
    NSURL *url = [NSURL URLWithString:@(urlString.c_str())];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[self.uiWebView mainFrame] loadRequest:request];
}

- (void)loadFile:(const std::string &)filePath {
    if (!self.uiWebView) {[self setupWebView];}
    NSURL *url = [NSURL fileURLWithPath:@(filePath.c_str())];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[self.uiWebView mainFrame] loadRequest:request];
}

- (void)stopLoading {
    [[self.uiWebView mainFrame] stopLoading];
}

- (void)reload {
    [[self.uiWebView mainFrame] reload];
}

- (BOOL)canGoForward {
    return self.uiWebView.canGoForward;
}

- (BOOL)canGoBack {
    return self.uiWebView.canGoBack;
}

- (void)goBack {
    [self.uiWebView goBack];
}

- (void)goForward {
    [self.uiWebView goForward];
}

- (void)evaluateJS:(const std::string &)js {
    if (!self.uiWebView) {[self setupWebView];}
    [self.uiWebView stringByEvaluatingJavaScriptFromString:@(js.c_str())];
}

//! @TODO: NOT SURE IF OSX HAS THIS FUNCTIONALITY
////----------------------!!!!!!!!!!!----------------------
- (void)setScalesPageToFit:(const bool)scalesPageToFit {
    //self.uiWebView.scalesPageToFit = scalesPageToFit;
}


#pragma mark - Delegates
// From WebPolicyDelegate
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    if ([actionInformation[WebActionNavigationTypeKey] intValue] == WebNavigationTypeOther) {
        [listener use];
        
    } else {
        
        NSString *url = [[request URL] absoluteString];
        if ([[[request URL] scheme] isEqualToString:self.jsScheme]) {
            self.onJsCallback([url UTF8String]);
            [listener ignore];
            return;
        }
        if (self.shouldStartLoading && url) {
            if (self.shouldStartLoading([url UTF8String])) {
                [listener use];
                return;
            } else {
                [listener ignore];
                return;
            }
        }
        
        [listener use];
    }
}

// From WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (self.didFinishLoading) {
        NSString *url = [[frame.dataSource.request URL] absoluteString];
        self.didFinishLoading([url UTF8String]);
    }
}

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (self.didFailLoading) {
        NSString *url = error.userInfo[NSURLErrorFailingURLStringErrorKey];
        if (url) {
            self.didFailLoading([url UTF8String]);
        }
    }
}

@end



namespace cocos2d {
    namespace experimental {
        namespace ui{
            
            WebViewImpl::WebViewImpl(WebView *webView)
            : _uiWebViewWrapper([UIWebViewWrapper webViewWrapper]),
            _webView(webView) {
                [_uiWebViewWrapper retain];
                
//                _uiWebViewWrapper.shouldStartLoading = [this](std::string url) {
//                    if (this->_webView->_onShouldStartLoading) {
//                        return this->_webView->_onShouldStartLoading(this->_webView, url);
//                    }
//                    return true;
//                };
//                _uiWebViewWrapper.didFinishLoading = [this](std::string url) {
//                    if (this->_webView->_onDidFinishLoading) {
//                        this->_webView->_onDidFinishLoading(this->_webView, url);
//                    }
//                };
//                _uiWebViewWrapper.didFailLoading = [this](std::string url) {
//                    if (this->_webView->_onDidFailLoading) {
//                        this->_webView->_onDidFailLoading(this->_webView, url);
//                    }
//                };
//                _uiWebViewWrapper.onJsCallback = [this](std::string url) {
//                    if (this->_webView->_onJSCallback) {
//                        this->_webView->_onJSCallback(this->_webView, url);
//                    }
//                };
            }
            
            WebViewImpl::~WebViewImpl(){
                [_uiWebViewWrapper release];
                _uiWebViewWrapper = nullptr;
            }
            
            void WebViewImpl::setJavascriptInterfaceScheme(const std::string &scheme) {
                [_uiWebViewWrapper setJavascriptInterfaceScheme:scheme];
            }
            
            void WebViewImpl::loadData(const Data &data,
                                       const std::string &MIMEType,
                                       const std::string &encoding,
                                       const std::string &baseURL) {
                
                std::string dataString(reinterpret_cast<char *>(data.getBytes()), static_cast<unsigned int>(data.getSize()));
                [_uiWebViewWrapper loadData:dataString MIMEType:MIMEType textEncodingName:encoding baseURL:baseURL];
            }
            
            void WebViewImpl::loadHTMLString(const std::string &string, const std::string &baseURL) {
                [_uiWebViewWrapper loadHTMLString:string baseURL:baseURL];
            }
            
            void WebViewImpl::loadURL(const std::string &url) {
                [_uiWebViewWrapper loadUrl:url];
            }
            
            void WebViewImpl::loadFile(const std::string &fileName) {
                auto fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(fileName);
                [_uiWebViewWrapper loadFile:fullPath];
            }
            
            void WebViewImpl::stopLoading() {
                [_uiWebViewWrapper stopLoading];
            }
            
            void WebViewImpl::reload() {
                [_uiWebViewWrapper reload];
            }
            
            bool WebViewImpl::canGoBack() {
                return _uiWebViewWrapper.canGoBack;
            }
            
            bool WebViewImpl::canGoForward() {
                return _uiWebViewWrapper.canGoForward;
            }
            
            void WebViewImpl::goBack() {
                [_uiWebViewWrapper goBack];
            }
            
            void WebViewImpl::goForward() {
                [_uiWebViewWrapper goForward];
            }
            
            void WebViewImpl::evaluateJS(const std::string &js) {
                [_uiWebViewWrapper evaluateJS:js];
            }
            
            void WebViewImpl::setScalesPageToFit(const bool scalesPageToFit) {
                [_uiWebViewWrapper setScalesPageToFit:scalesPageToFit];
            }
            
            void WebViewImpl::draw(cocos2d::Renderer *renderer, cocos2d::Mat4 const &transform, uint32_t flags) {
                if (flags & cocos2d::Node::FLAGS_TRANSFORM_DIRTY) {
                    
                    auto direcrot = cocos2d::Director::getInstance();
                    auto glView = direcrot->getOpenGLView();
                    auto frameSize = glView->getFrameSize();
                    
//                    auto scaleFactor = [static_cast<CCEAGLView *>(glView->getEAGLView()) contentScaleFactor];
                    
                    // @TODO: Implement OSX equivalent of scale factor
                    auto scaleFactor = 1.0;
                    
                    auto winSize = direcrot->getWinSize();
                    
                    auto leftBottom = this->_webView->convertToWorldSpace(cocos2d::Vec2::ZERO);
                    auto rightTop = this->_webView->convertToWorldSpace(cocos2d::Vec2(this->_webView->getContentSize().width, this->_webView->getContentSize().height));
                    
                    auto x = (frameSize.width / 2 + (leftBottom.x - winSize.width / 2) * glView->getScaleX()) / scaleFactor;
                    auto y = (frameSize.height / 2 - (rightTop.y - winSize.height / 2) * glView->getScaleY()) / scaleFactor;
                    auto width = (rightTop.x - leftBottom.x) * glView->getScaleX() / scaleFactor;
                    auto height = (rightTop.y - leftBottom.y) * glView->getScaleY() / scaleFactor;
                    
                    [_uiWebViewWrapper setFrameWithX:x
                                                   y:y
                                               width:width
                                              height:height];
                }
            }
            
            void WebViewImpl::setVisible(bool visible){
                [_uiWebViewWrapper setVisible:visible];
            }
            
        } // namespace ui
    } // namespace experimental
} //namespace cocos2d

#endif // CC_TARGET_PLATFORM == CC_PLATFORM_MAC
