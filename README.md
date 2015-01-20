ThumbnailService
================

ThumbnailService - is a service which helps you to generate asynchronically preview images.

Features
====

* Generates thumbnails asynchronically, on background thread. 
* Intelligent cache system. Caching request result in memory and disk. You can specify which kind of cache you want to use for specific request or for whole service.
* Flexible request managing. You can change queue and thread priorities for request at any time (even after request added to queue) as well as cancel request. 
* You can queue multiple requests to same thumbnail at same time, but only one operation will be performed, and its result delivered to all requests.
* ThumbnailService have a thin memory footprint, only one request performs at same time to decrease memory usage. All TSSource subclasses uses ImageIO framework with dealing with big images.
* It's stable, covered by unit-tests and used in few real projects.

Usage
====

For example you have a huge image, 20+ megabytes. And you want to show thumbnail of this image.

```objc
TSSourceImage *imageSource = [[TSSourceImage alloc] initWithImagePath:hugeImagePath];

TSRequest *thumbnailRequest = [TSRequest new];
thumbnailRequest.source = imageSource;
thumbnailRequest.size = self.imageView.bounds.size;

[thumbnailRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
  weakSelf.imageView.image = result;
}];
[thumbnailService enqueueRequest:thumbnailRequest]
```

That's all. Thumbnail with specified size will be returned to completion block.

Let's make an more complicated example. You want to show small(blurry) thumbnail first and then full size thumbnail.

It's simple! TSRequestGroupSequence is your friend!

```objc
TSSourceImage *imageSource = [[TSSourceImage alloc] initWithImagePath:imagePath];

CGSize smallThumbnailSize = CGSizeApplyAffineTransform(self.imageView.bounds.size, CGAffineTransformMakeScale(0.5, 0.5));

TSRequest *smallThumbRequest = [TSRequest new];
smallThumbRequest.source = imageSource;
smallThumbRequest.size = smallThumbnailSize;
smallThumbRequest.queuePriority = NSOperationQueuePriorityVeryHigh;
[smallThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
    weakSelf.imageView.image = result;
}];

TSRequest *bigThumbRequest = [TSRequest new];
bigThumbRequest.source = imageSource;
bigThumbRequest.size = self.imageView.bounds.size;
bigThumbRequest.queuePriority = NSOperationQueuePriorityHigh;

[bigThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
    weakSelf.imageView.image = result;
}];

TSRequestGroupSequence *group = [TSRequestGroupSequence new];
[group addRequest:smallThumbRequest];
[group addRequest:bigThumbRequest];

[thumbnailService enqueueRequestGroup:group];
```

In this example, thumbnailService executes sequentially smallThumbRequest then bigThumbRequest.

Sometimes you want to execute request synchonically. For example if image is already cached on disk, it is cheap to load on main thread.

```objc 
if ([thumbnailService hasDiskCacheForRequest:request]) {
    [thumbnailService executeRequest:request];
} else {
    [thumbnailService enqueueRequest:request];
}
```

So, what about proactive caching? Yes, it is designed for it!
You have a PDF document and want to precache all pages in your reader. It is a quite simple too:

```objc
- (void) precachePagesForDocument:(CGPDFDocumentRef)document withName:(NSString *)documentName
{
    NSUInteger pagesCount = CGPDFDocumentGetNumberOfPages(document);
    for (int i = 1; i < pagesCount; i++) {
        
        CGPDFPageRef page = CGPDFDocumentGetPage(document, i);
        TSRequest *request = [TSRequest new];
        request.source = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
        request.size = kThumbnailSize;
        request.queuePriority = NSOperationQueuePriorityVeryLow;
        request.shouldCacheInMemory = NO;
        [request setThumbnailCompletion:^(UIImage *result, NSError *error) { /* You have to pass it empty, not nil */ }];
        if (![thumbnailService hasDiskCacheForRequest:request]) {
            [thumbnailService enqueueRequest:request];
        }
    }
}
```

and at same time you can request for thumbnail in reader:

```objc
- (void) loadThumbnailAtIndex:(NSInteger)index intoImageView:(UIImageView *)imageView
{
    CGPDFPageRef page = CGPDFDocumentGetPage(document, index);

    TSRequest *request = [TSRequest new];
    request.source = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
    request.size = kThumbnailSize;
    request.queuePriority = TSRequestQueuePriorityVeryHigh;
    [thumbnailService enqueueRequest:request];
}
```

ThumbnailService will not perform requests twice, it combine them and perform by single operation with priority of highest request priority.

When you implementing reader with scrolling ability don't forget to cancel requests which you dont want (requests for invisible items).

```objc
UIImageView *reusableImageView = ...
TSRequest *oldRequest = reusableImageView.currentThumbnailRequest;
[oldRequest cancel];

TSRequest *newRequest = ...
[thumbnailService enqueueRequest:newRequest];
reusableImageView.currentThumbnailRequest = newRequest;
```
This way will guarantee that visible items will be filled by thumbnail with minimum possible time.

Installation
====
Prefered way is using cocoapods

```
pod 'ThumbnailService'
```
But you also can import sources or use as static library

Extending
====

You can add your own thumbnail source by subclassing TSSource or other source. See ThumbnailServiceDemo for more information.

Demos
====

Clone and check demos 

* ThumbnailServiceDemo - shows basic usage of ThumbnailService and available TSSource (ALAssets, Images, Videos, PDFs).
* PDFReaderDemo - shows a basic PDF reader with a quite smooth behaviour. Try to add your PDF files into xcode project and run!
