//////////////////////////////////////////////////////////////////////////////////////
//
//	This is a modified version of the library created by Piotr Walczyszyn in order to
//	provide application state persistence for PlayBook applications created using 
//	ActionScript and QNX UI libraries.
//	
//	If you want to enable persistance for your application you need to call the constructor
//	with the second argument true:
//		navigator = new ViewNavigator(this, true);
//
//	All the screens must extend the org.corlan.qnxutils.BaseView class. 

//	ViewNavigator will automatically persist the current Screens stack, current screen, and 
// 	the data objects for each screen from the stack. So when you want to have some values
//	saved for a screen (current selection in a list, the text of text input fields, you make
// 	sure you save this data into an Object instance and you assign this Object to the
//	data property.
//
//	For more see the examples from http://corlan.org/
// 
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//
//	Copyright 2011 Piotr Walczyszyn
//	
//	This file is part of as3viewnavigator.
//
//	as3viewnavigator is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//	
//	as3viewnavigator is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//	
//	You should have received a copy of the GNU General Public License
//	along with as3viewnavigator.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////

package org.corlan.asviews
{
	import caurina.transitions.Tweener;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.net.registerClassAlias;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Container;
	
	import org.corlan.asviews.IView;
	import org.corlan.asviews.ViewPersistence;

	public class ViewNavigator
	{
		protected var parent:Sprite;
		protected var views:Vector.<IView> = new Vector.<IView>;
		protected var _poppedViewReturnedObject:Object;
		
		/**
		 * Views transition duration, default value is 0.5s.
		 */
		public var transitionTime:Number = 0.5;

		private var sessionCacheEnabled:Boolean;
		private var so:SharedObject;
		
		private static const HISTORY:String = "history";
		private var addedToStage:Boolean = false;
		private var homeScreen:Class;
		
		/**
		 * ViewNavigator constructor, it accepts one parameter with a parent sprite.
		 * 
		 * @param parent - parent application sprite.
		 */
		public function ViewNavigator(parent:Sprite, sessionCacheEnabled:Boolean = false)
		{
			this.parent = parent;
			this.sessionCacheEnabled = sessionCacheEnabled;
			if (sessionCacheEnabled) {
				//register class must be called before SharedObject.getLocal()
				registerClassAlias("org.corlan.asviews.ViewPersistence", org.corlan.asviews.ViewPersistence);
				so = SharedObject.getLocal("asviewapp");
				parent.addEventListener(Event.DEACTIVATE, prepareForClosing);
			}
			parent.addEventListener(Event.ADDED_TO_STAGE, parent_addedToStageHandler);
		}
		
		protected function parent_addedToStageHandler(event:Event):void
		{
			trace("ViewNavigator parent_addedToStageHandler");
			addedToStage = true;
			parent.removeEventListener(Event.ADDED_TO_STAGE, parent_addedToStageHandler);
			//read the history
			if (sessionCacheEnabled) {
				var fromPersistence:Vector.<ViewPersistence> = so.data[HISTORY];
				var view:IView;
				var factory:Class;
				if (fromPersistence && fromPersistence.length > 0) {
					for (var i:int = 0; i < fromPersistence.length - 1; i++) {
						//todo recreate the views
						factory = fromPersistence[i].factory;
						view = new factory(fromPersistence[i].data);
						view.navigator = this;
						(view as DisplayObject).width = parent.stage.stageWidth;
						(view as DisplayObject).height = parent.stage.stageHeight;
						(view as DisplayObject).x = 0 - parent.stage.stageWidth;
						(view as DisplayObject).y = 0;
						if (fromPersistence.length > 1) {
							views.push(view);
						}
					}
					//attach the view bellow to stage
					if (views.length > 0) {
						parent.addChild(views[views.length - 1] as DisplayObject);
					}
					//display the last view from the stack;
					pushView(fromPersistence[i].factory, fromPersistence[i].data);
				}
			}
			if (!sessionCacheEnabled || views.length == 0) {
				//set the first screen if there are no screens in history;
				pushView(homeScreen);
			}
			parent.stage.addEventListener(Event.RESIZE, stage_resizeHandler);
		}
		
		public function prepareForClosing(e:Event):void 
		{
			if (sessionCacheEnabled) {
				var tmp:IView;
				var item:ViewPersistence;
				var toSave:Vector.<ViewPersistence> = new Vector.<ViewPersistence>();
				for (var i:int = 0; i < views.length; i++) {
					tmp = views[i] as IView;
					item = new ViewPersistence(getDefinitionByName(getQualifiedClassName(tmp)) as Class, tmp.data);
					toSave.push(item);
				}
				so.data[HISTORY] = toSave;
				so.flush();
			}
		}

		protected function stage_resizeHandler(event:Event):void
		{
			for each(var view:IView in views) {
				(view as BaseView).setSize(parent.stage.stageWidth, parent.stage.stageHeight);
			}
		}

		/**
		 * Adds view container on top of the stack. 
		 * 
		 * If added view implements IView interface it will also inject the reference to
		 * this navigator instance.
		 * 
		 * @see com.riaspace.as3viewnavigator.IView
		 * 
		 * @param view - Sprite to add
		 */
		public function pushView(factory:Class, data:Object = null):void
		{
			//delay the push until we check for history
			//in parent_addedToStageHandler()
			if (sessionCacheEnabled && !addedToStage) {
				homeScreen = factory;
				return;
			}
			var view:IView = new factory(data) as IView;
			
			// if pushed view is an IView setting navigator reference
			view.navigator = this;
			// Setting size of the added view
			(view as DisplayObject).width = parent.stage.stageWidth; 
			(view as DisplayObject).height = parent.stage.stageHeight;
			
			// Getting width of the stage
			var stageWidth:Number = parent.stage.stageWidth;
			
			// Setting x position to the right outside the screen
			(view as DisplayObject).x = stageWidth;
			// Setting y to the top of the screen
			(view as DisplayObject).y = 0;
			
			// Adding view to the parent
			parent.addChild((view as DisplayObject));
			
			var currentView:IView;
			if (views.length > 0)
			{
				// Getting current view from the stack
				currentView = views[views.length - 1];
				// Tweening currentView to the right outside the screen
				Tweener.addTween(currentView, {x : -stageWidth, time : transitionTime});
			}
			
			// Tweening added view
			Tweener.addTween(view, 
				{
					x : 0, 
					time : transitionTime, 
					onComplete:function():void
					{
						if (currentView)
							parent.removeChild(currentView as DisplayObject);
					}
				});
			// Adding current view to the stack
			views.push(view);
		}
		
		/**
		 * Pops current view from the top of the stack.
		 */
		public function popView():void
		{
			// Getting width of the stage
			var stageWidth:Number = parent.stage.stageWidth;

			var currentView:IView;
			if (views.length > 0)
			{
				// Getting current view from the stack
				currentView = views[views.length - 1];
				
				// Getting below view
				var belowView:IView;
				if (views.length > 1) {
					belowView = views[views.length - 2];
				}
				
				// Tweening currentView to the right outside the screen
				Tweener.addTween(currentView, 
					{
						x : stageWidth, 
						time : transitionTime, 
						onComplete:function():void
						{
							views.pop();
							parent.removeChild(currentView as DisplayObject);
							
							if (currentView is IView)
								_poppedViewReturnedObject = 
									IView(currentView).viewReturnObject;
							else
								_poppedViewReturnedObject = null;
						}
					});
				
				// Tweening view from below
				if (belowView)
				{
					parent.addChild(belowView as DisplayObject);
					Tweener.addTween(belowView, {x : 0, time : transitionTime});
				}
			}
		}
		
		/**
		 * Pops to the first view from the very top.
		 */
		public function popToFirstView():void
		{
			if (views.length > 1)
			{
				// Removing views except the bottom and the top one
				if (views.length > 2)
					views.splice(1, views.length - 2);
				
				// Poping top view to have nice transition
				popView();
			}
		}
		
		/**
		 * Pops all views from the stack.
		 */
		public function popAll():void
		{
			// Removing views except the top one
			views.splice(0, views.length - 1);
			// Poping top view to have nice transition
			popView();
		}
		
		/**
		 * Returns object value returned by popped view. 
		 * View has to implement IView interface in order to have this value returned.
		 */
		public function get poppedViewReturnedObject():Object
		{
			return _poppedViewReturnedObject;
		}
		
		/**
		 * Returns number of views managed by this navigator.
		 */
		public function get length():int
		{
			return views.length;
		}
	}
}