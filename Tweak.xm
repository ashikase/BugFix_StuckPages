/**
 * Name: Bug Fix: Stuck Pages
 * Type: iOS SpringBoard extension (MobileSubstrate-based)
 * Desc: Prevent SpringBoard bug that resets icon layouts.
 *
 *       This bug exists in iOS 4.x; it may also exist in older (and newer)
 *       firmware. It affects all devices, jailbroken and non-jailbroken
 *       alike.
 *
 *       The bug can be reproduced by performing the following steps.
 *       WARNING: This will cause your icon layout to be reset (i.e. the
 *           positions of your icons will be restored to a built-in default,
 *           and any folders that you have created will be removed).
 *
 *       1) Tap and hold any icon to enter edit ('wiggle') mode.
 *       2) Upon entering edit mode, a new, empty page will be added to the far
 *          right; swipe to this page.
 *       3) Slide this empty page to the right, enough so that just over half of
 *          the previous page is visible on the left.
 *       4) When you lift your finger the view should scroll to the previous
 *          page; while it is scrolling, press your device's Home button.
 *          (Note that this must be done very quickly.)
 *       5) Springboard should appear to be "stuck" between two pages.
 *       6) Without moving the pages back to normal, tap and hold any icon on
 *          the right-most of the two page to re-enter edit mode.
 *       7) Let go of the held icon; a different icon on the left-most page will
 *          disappear.
 *       8) To recover this icon, restart SpringBoard (or reboot your device).
 *       9) When SpringBoard restarts, your icon layout will be reset.
 *
 *       Credit for discovering this issue and providing the steps (modified
 *       above) to reproduce it goes to Kyle Levin.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: New BSD (See LICENSE file for details)
 *
 * Last-modified: 2011-08-09 18:50:22
 */


@interface SBIconController : NSObject
- (BOOL)isEditing;
- (void)setIsEditing:(BOOL)editing;
@end

static BOOL shouldEndEditing_ = NO;

%hook SBIconController

- (void)setIsEditing:(BOOL)editing
{
    if (!editing && [self isEditing]) {
        // Is request to end edit mode
        UIScrollView *_scrollView = MSHookIvar<UIScrollView *>(self, "_scrollView");
        if ([_scrollView isDecelerating]) {
            // Don't allow change to edit mode while scroll view is decelerating.
            // NOTE: When edit mode ends, the content of the scroll view
            //       is modified (the empty page is removed). Allowing this
            //       to occur while the scroll view is changing pages is what
            //       causes the bug.
            shouldEndEditing_ = YES;
            return;
        }
        // Fall-through
    }

    // Call original implementation
    %orig;
}

- (void)scrollViewDidEndDecelerating:(id)scrollView
{
    %orig;

    if (shouldEndEditing_) {
        // Now that deceleration has ended, it is safe to end edit mode
        [self setIsEditing:NO];
        shouldEndEditing_ = NO;
    }
}

%end

/* vim: set filetype=objcpp sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
