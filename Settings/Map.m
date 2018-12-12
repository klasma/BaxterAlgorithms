classdef Map < handle
    % Map container where values of any type are stored under strings keys.
    %
    % Currently the the map is implemented using a struct, and the class
    % serves mostly as a wrapper for the struct. The class is pass by
    % reference, and has a number of convenient functions which are not
    % available in the struct class, such as numerical indexing using the
    % Get function. Values of any kind can be stored in the map.
    
    properties
        values  % Struct containing the values.
        keys    % String keys corresponding to the values (fields in the struct).
    end
    
    methods
        function this = Map(varargin)
            % Generates an empty Map or constructs it from a struct.
            %
            % Inputs:
            % varargin{1} - An optional input in the form of a struct where
            %               the field names become keys for the values in
            %               the struct. If this input is not given, the
            %               constructor returns an empty map.
            
            switch nargin
                case 0
                    % Construct empty Map.
                    this.values = struct();
                    this.keys = {};
                case 1
                    % Convert struct to Map.
                    this.values = varargin{1};
                    this.keys = fieldnames(this.values);
                otherwise
                    error('ParameterSet takes 0 or 1 inputs, not %d.\n', nargin)
            end
        end
        
        function Add(this, aKey, aValue, aIndex)
            % Adds a new key and a corresponding value to the map.
            %
            % Inputs:
            % aKey - The new key (string).
            % aValue - New value corresponding to the key.
            % aIndex - Index that the key will get in the map. If this
            %          input is omitted, the key is added at the end of the
            %          map.
            %
            % See also:
            % Get, Set, Has
            
            % Add the key at the end.
            this.values.(aKey) = aValue;
            this.keys = [this.keys; {aKey}];
            
            % Change the order of the keys (and the values) if the added
            % key should not be at the end.
            if nargin > 3
                numSettings = length(this.keys);
                order = [1:aIndex-1 numSettings aIndex:numSettings-1];
                this.values = orderfields(this.values, order);
                this.keys = this.keys(order);
            end
        end
        
        function oMap = Clone(this)
            % Deep copies the set, but does not deep copy the values.
            %
            % Outputs:
            % oMap - Deep copy of the current Map. The values are just
            %        copied, so if they are handles, they will point to the
            %        same objects as the values in the current set.
            
            oMap = Map();
            oMap.keys = this.keys;
            oMap.values = this.values;
        end
        
        function oValue = Get(this, aIndex)
            % Returns a value from the map.
            %
            % Inputs:
            % aIndex - The string key corresponding to the desired value,
            %          or the numerical index of the value in the set. The
            %          values are indexed in the order that they are added,
            %          and the indexing starts from 1.
            %
            % oValue - Value corresponding to the requested key or index.
            %
            % See also:
            % Set, Add
            
            if ischar(aIndex)
                oValue = this.values.(aIndex);
            else
                oValue = this.values.(this.keys{aIndex});
            end
        end
        
        function oKey = GetLabel(this, aIndex)
            % Returns a key from the map.
            %
            % Inputs:
            % aIndex - Index of the desired key.
            %
            % oKey - Desired key.
            
            oKey = this.keys{aIndex};
        end
        
        function oKeys = GetLabels(this)
            % Returns a cell array with all keys.
            
            oKeys = this.keys;
        end
        
        function oHas = Has(this, aKey)
            % Checks if the map has a specific key.
            %
            % Inputs:
            % aKey - Key to check for (string).
            %
            % Outputs:
            % oHas - Binary output which is true if the map has the key.
            
            oHas = isfield(this.values, aKey);
        end
        
        function Set(this, aKey, aValue)
            % Changes one of the values in the map.
            %
            % Inputs:
            % aKey - The string key or the numerical index of for which
            %        the value will be changed. The values are indexed in
            %        the order that they are added, and the indexing
            %        starts from 1. If the key or index does not exist,
            %        the value has to be added using Add instead of Set.
            % aValue - New value.
            %
            % See also:
            % Add, Get, Has
            
            if ischar(aKey)
                assert(this.Has(aKey),...
                    sprintf('There is no field %s in the map.\n', aKey))
                this.values.(aKey) = aValue;
            else
                assert(aKey <= this.Size(),...
                    sprintf(['The map has %d fields and you tried to '...
                    'access field %d.\n'], this.Size(), aKey))
                this.values.(this.keys{aKey}) = aValue;
            end
        end
        
        function oSize = Size(this)
            % Returns the number of keys in the map.
            
            oSize = length(this.keys);
        end
    end
end