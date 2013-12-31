package dorkbots.dorkbots_iso.room
{
	import flash.display.MovieClip;
	import flash.errors.IllegalOperationError;
	
	import dorkbots.dorkbots_iso.entity.IEnemy;

	public class IsoRoomData implements IIsoRoomData
	{
		private var _stasis:Boolean = false;
		
		protected var _roomWalkable:Array;
		protected var _roomPickups:Array;
		protected var _roomTileArt:Array;
		private var _roomTileArtWithHeight:Array;
		protected var _roomTriggers:Array;
		protected var _roomEntities:Array;
		
		private var _entitiesGrid:Array;
		
		private var _roomNodeGridWidth:uint;
		private var _roomNodeGridHeight:uint;
		
		protected var _nodeWidth:uint = 50;
		
		// hero
		protected var heroClass:Class;
		private var _hero:MovieClip;
		protected var _heroHalfSize:uint = 20;
		
		// enemy
		protected var enemyClass:Class;
		protected var _enemyHalfSize:uint = 20;
		private var _enemies:Vector.<IEnemy> = new Vector.<IEnemy>();
		private var _enemiesWalkable:Array = new Array();
		
		//the tiles
		protected var tileArtClass:Class;
		private var _tileArt:MovieClip;
		protected var _tileArtWithHeight:Vector.<uint>;
		protected var tilePickupClass:Class;
		private var _tilePickup:MovieClip;
		
		//to handle direction movement
		protected var _speed:uint = 6;
		protected var _heroFacing:String = "south";
		
		public final function IsoRoomData()
		{
		}

		public final function init():void
		{
			_roomNodeGridWidth = _roomWalkable[0].length;
			_roomNodeGridHeight = _roomWalkable.length;
			
			initEntitiesGrid();
			
			setupTileArtWithHeight();
		}
		
		public final function wake():void
		{
			_stasis = false;
			
			initEntitiesGrid();
		}
		
		// SET UP 3D ARRAY FOR ENTITIES
		private function initEntitiesGrid():void
		{
			_entitiesGrid = new Array();
			for (var i:uint = 0; i < _roomNodeGridHeight; i++)
			{
				_entitiesGrid[i] = new Array();
				for (var j:uint = 0; j < _roomNodeGridWidth; j++)
				{
					_entitiesGrid[i][j] = new Array();
				}
			}
		}
		
		// ABSTRACT method. Must be overridden by a child class.
		protected function setupTileArtWithHeight():void
		{
			// use this method to register/add tile art types that have height, that could be in the foreground or cover moving entities.
			throw new IllegalOperationError("The setupTileArtWithHeight method is an ABSTRACT method and must be overridden in a child class!! Use this method to register/add tile art types that have height, that could be in the foreground or cover moving entities.");
		}
		
		public final function putInStasis():void
		{
			_stasis = true;
			_hero = null;
			_tileArt = null;
			
			_roomTileArtWithHeight.length = 0;
			_roomTileArtWithHeight = null;
			_tileArtWithHeight.length = 0;
			_tileArtWithHeight = null;
			
			_entitiesGrid.length = 0;
			_entitiesGrid = null;
		}
		
		public final function dispose():void
		{
			_roomWalkable.length = 0;
			_roomWalkable = null;
			_roomTileArt.length = 0;
			_roomTileArt = null;
			_roomTriggers.length = 0;
			_roomTriggers = null;
			_roomPickups.length = 0;
			_roomPickups = null;
			_roomEntities.length = 0;
			_roomEntities = null;
			
			heroClass = null;
			enemyClass = null;
			_enemies.length = 0;
			tileArtClass = null;
			tilePickupClass = null;
			
			putInStasis();
		}
		
		public final function get stasis():Boolean
		{
			return _stasis;
		}
		
		public final function get heroFacing():String
		{
			return _heroFacing;
		}

		public final function get speed():uint
		{
			return _speed;
		}

		public final function get tileArt():MovieClip
		{
			if (_tileArt == null) _tileArt = new tileArtClass();
			return _tileArt;
		}

		public final function get tilePickup():MovieClip
		{
			if (_tilePickup == null) _tilePickup = new tilePickupClass();
			return _tilePickup;
		}
		
		public final function get hero():MovieClip
		{
			if (_hero == null) _hero = new heroClass();
			return _hero;
		}

		public final function get heroHalfSize():uint
		{
			return _heroHalfSize;
		}
		
		public function get enemyHalfSize():uint
		{
			return _enemyHalfSize;
		}
		
		public function createEnemy(type:uint):MovieClip
		{
			return new enemyClass();
		}
		
		public final function set enemies(value:Vector.<IEnemy>):void
		{
			_enemies = value;
		}
		
		public final function get enemies():Vector.<IEnemy>
		{
			return _enemies;
		}
		
		public final function get enemiesWalkable():Array
		{
			return _enemiesWalkable;
		}
		
		public final function set enemiesWalkable(value:Array):void
		{
			_enemiesWalkable = value;
		}

		public final function get nodeWidth():uint
		{
			return _nodeWidth;
		}
		
		public final function get roomNodeGridHeight():uint
		{
			return _roomNodeGridHeight;
		}
		
		public final function get roomNodeGridWidth():uint
		{
			return _roomNodeGridWidth;
		}
		
		public final function get roomWalkable():Array
		{
			return _roomWalkable;
		}
		
		public final function get roomTileArt():Array
		{
			return _roomTileArt;
		}
		
		public final function get roomTileArtWithHeight():Array
		{
			return _roomTileArtWithHeight;
		}
		
		public final function set roomTileArtWithHeight(value:Array):void
		{
			_roomTileArtWithHeight = value;
		}
		
		public final function get tileArtWithHeight():Vector.<uint>
		{
			return _tileArtWithHeight;
		}
		
		public final function get roomTriggers():Array
		{
			return _roomTriggers;
		}
		
		public final function get roomPickups():Array
		{
			return _roomPickups;
		}
		
		public final function get roomEntities():Array
		{
			return _roomEntities;
		}
		
		public final function get entitiesGrid():Array
		{
			return _entitiesGrid;
		}
	}
}