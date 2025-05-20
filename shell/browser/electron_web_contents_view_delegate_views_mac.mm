// Copyright 2014 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "shell/browser/renderer_host/electron_render_widget_host_view_mac_delegate.h"
#include "shell/browser/electron_web_contents_view_delegate_views_mac.h"

ElectronWebContentsViewDelegateViewsMac::ElectronWebContentsViewDelegateViewsMac(
content::WebContents* web_contents) : web_contents_(web_contents) {}

ElectronWebContentsViewDelegateViewsMac::~ElectronWebContentsViewDelegateViewsMac() = default;

NSObject<RenderWidgetHostViewMacDelegate>*
ElectronWebContentsViewDelegateViewsMac::GetDelegateForHost(
    content::RenderWidgetHost* render_widget_host,
    bool is_popup) {
  // We don't need a delegate for popups since they don't have
  // overscroll.
  if (is_popup) {
    return nil;
  }
  
  return [[ElectronRenderWidgetHostViewMacDelegate alloc]
      initWithRenderWidgetHost:render_widget_host];
}

std::unique_ptr<content::WebContentsViewDelegate> CreateWebContentsViewDelegate(
    content::WebContents* web_contents) {
  return std::make_unique<ElectronWebContentsViewDelegateViewsMac>(web_contents);
}
