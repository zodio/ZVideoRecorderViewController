## PBJVideoPlayer
'PBJVideoPlayer' is a simple iOS video player, featuring touch-to-play.

When integrated, it provides mobile apps with the ability to play content whether it is local or on a remote server. The video player supports both iOS 6 and iOS 7 and is 64-bit compatible.

Please review the [release history](https://github.com/piemonte/PBJVideoPlayer/releases) for more information.

If you have questions or ideas, the [github issues page](https://github.com/piemonte/PBJVideoPlayer/issues) is a great means to start a discussion but also this allows others to benefit and chime in on the project too.

## Installation

[CocoaPods](http://cocoapods.org) is the recommended method of installing PBJVideoPlayer, just to add the following line to your `Podfile`:

#### Podfile

```ruby
pod 'PBJVideoPlayer'
```

## Usage
```objective-c
#import "PBJVideoPlayerController.h"
```

```objective-c
// allocate controller
_videoPlayerController = [[PBJVideoPlayerController alloc] init];
_videoPlayerController.delegate = self;
_videoPlayerController.view.frame = self.view.bounds;

// setup media
_videoPlayerController.videoPath = PBJViewControllerVideoPath;

// present
[self addChildViewController:_videoPlayerController];
[self.view addSubview:_videoPlayerController.view];
[_videoPlayerController didMoveToParentViewController:self];
```

## License

'PBJVideoPlayer' is available under the MIT license, see the [LICENSE](https://github.com/piemonte/PBJVideoPlayer/blob/master/LICENSE) file for more information.
