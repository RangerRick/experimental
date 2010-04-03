package com.befunk.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.user.client.ui.Label;
import com.google.gwt.user.client.ui.RootPanel;


/**
 * Entry point classes define <code>onModuleLoad()</code>.
 */
public class FinkServer implements EntryPoint
{

  /**
   * This is the entry point method.
   */
  public void onModuleLoad()
  {
     final Label label = new Label ( "gwt-maven-plugin Archetype :: Yo!" );
     RootPanel.get().add( label );
  }
}
