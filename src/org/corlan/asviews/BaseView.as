//////////////////////////////////////////////////////////////////////////////////////
//
//	Copyright 2011 Mihai Corlan
//	http://corlan.org
//	
//	This file is part of of org.corlan.qnxutils a library that extends
//	com.riaspace.as3viewnavigator created by Piotr Walczyszyn. It extends
// 	the capabilities to provide Screen Navigation for PlayBook ActionScript
//	projects.
//
//	this is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//	
//	this is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//	
//	You should have received a copy of the GNU General Public License
//	along with as3viewnavigator.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//
//	To use this class you have to extend it in your application and make sure 
//	you override the createUI() and applyData() methods.
//
//	createUI() method is where you build your UI using the QNX UI components.

//	applyData() method is called automatically when the view is added to stage 
//	You can use this method to restore the UI values to those stored in the data property
//
//////////////////////////////////////////////////////////////////////////////////////
package org.corlan.asviews {
	import flash.events.Event;
	
	import org.corlan.asviews.IView;
	import org.corlan.asviews.ViewNavigator;
	import qnx.ui.core.Container;
	
	public class BaseView extends Container implements IView {
		
		private var _data:Object;
		private var _navigator:ViewNavigator;
		
		public function BaseView(d:Object=null, s:Number=100, su:String="percent") {
			super(s, su);
			data = d;
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			createUI();
		}
		
		/**
		 * The child classes must override this method
		 */ 
		protected function createUI():void {
			throw(new Error("You must override createUI() method of org.corlan.qnxutils.BaseView", 100));
		}
		
		/**
		 * The child classes must override this method.
		 * You use this method to 
		 */ 
		protected function applyData():void {
			throw(new Error("You must override applyData() method of org.corlan.qnxutils.BaseView", 100));
		}
		
		private function addedToStageHandler(e:Event):void {
			trace("BaseView added to stage");
			applyData();
		}
		
		public function get navigator():ViewNavigator {
			return _navigator;
		}
		
		public function set navigator(value:ViewNavigator):void {
			_navigator = value;
		}
		
		public function get viewReturnObject():Object {
			return null;
		}
		
		public function get data():Object {
			return _data;
		}
		
		public function set data(d:Object):void {
			_data = d;
		}
		
	}
}