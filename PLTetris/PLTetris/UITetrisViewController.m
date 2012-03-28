//
//  PLTetrisViewController.m
//  PLTetris
//
//  Created by Charles Magahern on 7/11/11.
//  Copyright 2011 omegaHern. All rights reserved.
//

#import "UITetrisViewController.h"
#import "PLTetrisView.h"
#import "PLTetronimo.h"

#define kControllerMoveSensitivity      22.0f
#define kControllerRotateSensitivity    5.0f
#define kControllerMoveDownSensitivity  20.0f


@interface UITetrisViewController ()

- (void)swipeDownGestureAction:(UISwipeGestureRecognizer *)recognizer;

@end


@implementation UITetrisViewController

- (id)init
{
    if ((self = [super init])) {
        // Setup Game
        tetrisGame = [[PLTetrisGame alloc] init];
        [tetrisGame setGameDelegate:self];
        [tetrisGame setGameSpeed:3.5];
        [tetrisGame startGame];
        
        
        // Setup View
        CGRect windowBounds = [[UIScreen mainScreen] bounds];
        PLTetrisView *tetrisView = [[PLTetrisView alloc] initWithFrame:CGRectMake(0.0, 0.0, windowBounds.size.width, windowBounds.size.height)];
        tetrisView.game = tetrisGame;
        self.view = tetrisView;
        [tetrisView release];
        
        
        // Setup controls
        _touchDistanceMoved = 0.0;
        UISwipeGestureRecognizer *swipeGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDownGestureAction:)];
        [swipeGR setDirection:UISwipeGestureRecognizerDirectionDown];
        [self.view addGestureRecognizer:swipeGR];
        [swipeGR release];
        
        
        // Setup Music
        NSError *err = nil;
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"tetris" withExtension:@"caf"];
        musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        musicPlayer.numberOfLoops = -1;
        [musicPlayer play];
    }
    
    return self;
}

- (void)dealloc
{
    if (tetrisGame != nil)
        [tetrisGame release];
    
    [musicPlayer stop];
    [musicPlayer release];
    [super dealloc];
}


#pragma mark - Touch Controls

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchDistanceMoved = 0.0;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint previous, now;
    CGFloat xDiff, yDiff;
    static CGFloat xDistanceMoved = 0.0;
    static CGFloat yDistanceMoved = 0.0;
    
    previous = [touch previousLocationInView:self.view];
    now = [touch locationInView:self.view];
    xDiff = now.x - previous.x;
    yDiff = now.y - previous.y;
    _touchDistanceMoved += fabsf(xDiff) + fabsf(yDiff);
    
    // Change in X direction?
    if ((xDistanceMoved > 0 && xDiff < 0) || (xDistanceMoved < 0 && xDiff > 0))
        xDistanceMoved = xDiff;
    else
        xDistanceMoved += xDiff;
    
    // Change in Y direction?
    if ((yDistanceMoved > 0 && yDiff < 0) || (yDistanceMoved < 0 && yDiff > 0))
        yDistanceMoved = yDiff;
    else
        yDistanceMoved += yDiff;
    
    if (fabsf(xDistanceMoved) >= kControllerMoveSensitivity) {
        if (xDistanceMoved < 0.0) {
            [tetrisGame moveTetronimo:PLTetronimoActionLeft];
        } else if (xDistanceMoved > 0.0) {
            [tetrisGame moveTetronimo:PLTetronimoActionRight];
        }
        
        xDistanceMoved = 0.0;
    }
    
    if (yDistanceMoved >= kControllerMoveDownSensitivity) {
        [tetrisGame moveTetronimo:PLTetronimoActionDown];
        
        yDistanceMoved = 0.0;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchDistanceMoved <= kControllerRotateSensitivity) {
        CGPoint pt = [[touches anyObject] locationInView:self.view];
        if (pt.x <= self.view.bounds.size.width / 2.0) {
            [tetrisGame rotateTetronimo:PLTetronimoActionLeft];
        } else {
            [tetrisGame rotateTetronimo:PLTetronimoActionRight];
        }
    }
}

- (void)swipeDownGestureAction:(UISwipeGestureRecognizer *)recognizer
{
    [tetrisGame dropTetronimo];
}


#pragma mark - View Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Tetris Game Delegate Methods

- (void)tetrisGameDidUpdate:(float)dt
{
    if (self.isViewLoaded)
        [(PLTetrisView *) self.view redraw];
}

- (void)shouldDisplayNextTetronimo:(PLTetronimo *)tetronimo
{
    if (self.isViewLoaded)
        [(PLTetrisView *) self.view updateNextTetronimoDisplay:tetronimo];
}

- (void)tetrisBoardDidChange
{
    if (self.isViewLoaded)
        [(PLTetrisView *) self.view setBoardIsDirty:YES];
}

- (void)shouldUpdateScore:(NSUInteger)score
{
    if (self.isViewLoaded)
        [(PLTetrisView *) self.view setScore:score];
}

- (void)clearedLinesAtRows:(NSUInteger[])rows count:(NSUInteger)count
{
    if (self.isViewLoaded)
        [(PLTetrisView *) self.view animateClearLinesAtRows:rows count:count];
}

- (void)gameOver
{
    NSString *message = [NSString stringWithFormat:@"Your Score: %d", tetrisGame.score];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game Over!" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}


#pragma mark - Alert View Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [(PLTetrisView *) self.view setScore:0];
    [tetrisGame startGame];
}


@end
