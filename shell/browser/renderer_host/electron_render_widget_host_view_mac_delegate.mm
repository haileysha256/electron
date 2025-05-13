// Copyright 2012 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "shell/browser/renderer_host/electron_render_widget_host_view_mac_delegate.h"

#include "base/strings/sys_string_conversions.h"
#include "components/spellcheck/browser/spellcheck_platform.h"
#include "components/spellcheck/common/spellcheck_panel.mojom.h"
#include "content/public/browser/render_process_host.h"
#include "content/public/browser/render_view_host.h"
#include "content/public/browser/render_widget_host.h"
#include "content/public/browser/web_contents.h"
#include "mojo/public/cpp/bindings/remote.h"
#include "services/service_manager/public/cpp/interface_provider.h"

@interface ElectronRenderWidgetHostViewMacDelegate ()

@property(readonly) content::WebContents* webContents;
@end

@implementation ElectronRenderWidgetHostViewMacDelegate {
  // The widget host (process + routing IDs) that this delegate is managing.
  int32_t _widgetProcessId;
  int32_t _widgetRoutingId;
}

- (instancetype)initWithRenderWidgetHost:
    (content::RenderWidgetHost*)renderWidgetHost {
  self = [super init];
  if (self) {
    _widgetProcessId = renderWidgetHost->GetProcess()->GetDeprecatedID();
    _widgetRoutingId = renderWidgetHost->GetRoutingID();
  }
  return self;
}


- (void)beginGestureWithEvent:(NSEvent*)event {
}

- (void)endGestureWithEvent:(NSEvent*)event {
}

- (void)touchesMovedWithEvent:(NSEvent*)event {
}

- (void)touchesBeganWithEvent:(NSEvent*)event {
}

- (void)touchesCancelledWithEvent:(NSEvent*)event {
}

- (void)touchesEndedWithEvent:(NSEvent*)event {
}

- (void)rendererHandledGestureScrollEvent:(const blink::WebGestureEvent&)event
                                 consumed:(BOOL)consumed {
}

- (void)rendererHandledOverscrollEvent:(const ui::DidOverscrollParams&)params {
}

- (void)rendererHandledWheelEvent:(const blink::WebMouseWheelEvent&)event
                         consumed:(BOOL)consumed {}

- (content::WebContents*)webContents {
  content::RenderWidgetHost* renderWidgetHost =
      content::RenderWidgetHost::FromID(_widgetProcessId, _widgetRoutingId);
  if (!renderWidgetHost) {
    return nullptr;
  }

  content::RenderViewHost* renderViewHost =
      content::RenderViewHost::From(renderWidgetHost);
  if (!renderViewHost) {
    return nullptr;
  }

  return content::WebContents::FromRenderViewHost(renderViewHost);
}

// Spellchecking methods
// The next five methods are implemented here since this class is the first
// responder for anything in the browser.

// This message is sent whenever the user specifies that a word should be
// changed from the spellChecker.
- (void)changeSpelling:(id)sender {
  content::WebContents* webContents = self.webContents;
  if (!webContents) {
    return;
  }

  // Grab the currently selected word from the spell panel, as this is the word
  // that we want to replace the selected word in the text with.
  NSString* newWord = [[sender selectedCell] stringValue];
  if (newWord != nil) {
    webContents->ReplaceMisspelling(base::SysNSStringToUTF16(newWord));
  }
}

// This message is sent by NSSpellChecker whenever the next word should be
// advanced to, either after a correction or clicking the "Find Next" button.
// This isn't documented anywhere useful, like in NSSpellProtocol.h with the
// other spelling panel methods. This is probably because Apple assumes that the
// the spelling panel will be used with an NSText, which will automatically
// catch this and advance to the next word for you. Thanks Apple.
// This is also called from the Edit -> Spelling -> Check Spelling menu item.
- (void)checkSpelling:(id)sender {
  content::WebContents* webContents = self.webContents;
  if (!webContents) {
    return;
  }

  if (content::RenderFrameHost* frame = webContents->GetFocusedFrame()) {
    mojo::Remote<spellcheck::mojom::SpellCheckPanel>
        focused_spell_check_panel_client;
    frame->GetRemoteInterfaces()->GetInterface(
        focused_spell_check_panel_client.BindNewPipeAndPassReceiver());
    focused_spell_check_panel_client->AdvanceToNextMisspelling();
  }
}

// This message is sent by the spelling panel whenever a word is ignored.
- (void)ignoreSpelling:(id)sender {
  // Ideally, we would ask the current RenderView for its tag, but that would
  // mean making a blocking IPC call from the browser. Instead,
  // spellcheck_platform::CheckSpelling remembers the last tag and
  // spellcheck_platform::IgnoreWord assumes that is the correct tag.
  NSString* wordToIgnore = [sender stringValue];
  if (wordToIgnore != nil)
    spellcheck_platform::IgnoreWord(nullptr,
                                    base::SysNSStringToUTF16(wordToIgnore));
}

- (void)showGuessPanel:(id)sender {
  content::WebContents* webContents = self.webContents;
  if (!webContents) {
    return;
  }

  const bool visible = spellcheck_platform::SpellingPanelVisible();

  if (content::RenderFrameHost* frame = webContents->GetFocusedFrame()) {
    mojo::Remote<spellcheck::mojom::SpellCheckPanel>
        focused_spell_check_panel_client;
    frame->GetRemoteInterfaces()->GetInterface(
        focused_spell_check_panel_client.BindNewPipeAndPassReceiver());
    focused_spell_check_panel_client->ToggleSpellPanel(visible);
  }
}



// END Spellchecking methods

@end
