[1m[1;34mActiveRecord::Core#methods[0m[0m: 
  <=>  connection_handler  eql?    frozen?                       hash       inspect       readonly!  set_transaction_state
  ==   encode_with         freeze  has_transactional_callbacks?  init_with  pretty_print  readonly?  slice                
[1m[1;34mActiveRecord::Persistence#methods[0m[0m: 
  becomes   decrement   delete    destroyed?  increment!   persisted?  toggle!  update!           update_attributes   update_column 
  becomes!  decrement!  destroy!  increment   new_record?  toggle      update   update_attribute  update_attributes!  update_columns
[1m[1;34mActiveRecord::Scoping#methods[0m[0m: initialize_internals_callback  populate_with_current_scope_attributes
[1m[1;34mActiveRecord::Sanitization#methods[0m[0m: quoted_id
[1m[1;34mActiveRecord::AttributeAssignment#methods[0m[0m: assign_attributes  attributes=
[1m[1;34mActiveModel::Conversion#methods[0m[0m: to_model  to_partial_path
[1m[1;34mActiveRecord::Integration#methods[0m[0m: cache_key  to_param
[1m[1;34mActiveModel::Validations#methods[0m[0m: errors  invalid?  read_attribute_for_validation  validates_with
[1m[1;34mActiveSupport::Callbacks#methods[0m[0m: run_callbacks
[1m[1;34mActiveModel::Validations::HelperMethods#methods[0m[0m: 
  validates_absence_of     validates_confirmation_of  validates_format_of     validates_length_of        validates_presence_of
  validates_acceptance_of  validates_exclusion_of     validates_inclusion_of  validates_numericality_of  validates_size_of    
[1m[1;34mActiveRecord::Validations#methods[0m[0m: valid?  validate  validate!
[1m[1;34mActiveRecord::Locking::Optimistic#methods[0m[0m: locking_enabled?
[1m[1;34mActiveRecord::Locking::Pessimistic#methods[0m[0m: lock!  with_lock
[1m[1;34mActiveModel::AttributeMethods#methods[0m[0m: attribute_missing  [1;31mmethod_missing[0m  respond_to_without_attributes?
[1m[1;34mActiveRecord::AttributeMethods#methods[0m[0m: []  []=  attribute_for_inspect  attribute_names  attribute_present?  attributes  has_attribute?  respond_to?
[1m[1;34mActiveRecord::AttributeMethods::Read#methods[0m[0m: _read_attribute  read_attribute
[1m[1;34mActiveRecord::AttributeMethods::BeforeTypeCast#methods[0m[0m: attributes_before_type_cast  read_attribute_before_type_cast
[1m[1;34mActiveRecord::AttributeMethods::Query#methods[0m[0m: query_attribute
[1m[1;34mActiveRecord::AttributeMethods::PrimaryKey#methods[0m[0m: to_key
[1m[1;34mActiveModel::Dirty#methods[0m[0m: attribute_changed?  attribute_was  attributes_changed_by_setter  changed  changed?  previous_changes  restore_attributes
[1m[1;34mActiveRecord::AttributeMethods::Dirty#methods[0m[0m: attribute_changed_in_place?  changed_attributes  changes  changes_applied  clear_changes_information
[1m[1;34mActiveRecord::Associations#methods[0m[0m: association  association_cache  clear_association_cache
[1m[1;34mActiveRecord::AutosaveAssociation#methods[0m[0m: 
  changed_for_autosave?  destroyed_by_association  destroyed_by_association=  mark_for_destruction  marked_for_destruction?  reload
[1m[1;34mActiveRecord::NestedAttributes#methods[0m[0m: _destroy
[1m[1;34mActiveRecord::Aggregations#methods[0m[0m: clear_aggregation_cache
[1m[1;34mActiveRecord::Transactions#methods[0m[0m: 
  add_to_transaction  committed!  destroy  rollback_active_record_state!  rolledback!  save  save!  transaction  with_transaction_returning_status
[1m[1;34mActiveRecord::NoTouching#methods[0m[0m: no_touching?  touch
[1m[1;34mActiveModel::Serialization#methods[0m[0m: read_attribute_for_serialization
[1m[1;34mActiveModel::Serializers::JSON#methods[0m[0m: as_json  from_json
[1m[1;34mActiveModel::Serializers::Xml#methods[0m[0m: from_xml
[1m[1;34mActiveRecord::Serialization#methods[0m[0m: serializable_hash  to_xml
[1m[1;34mActiveRecord::Base#methods[0m[0m: 
  _commit_callbacks          _run_rollback_callbacks    aggregate_reflections?       nested_attributes_options                
  _commit_callbacks=         _run_save_callbacks        attribute_aliases            nested_attributes_options?               
  _commit_callbacks?         _run_touch_callbacks       attribute_aliases?           partial_writes                           
  _create_callbacks          _run_update_callbacks      attribute_method_matchers    partial_writes?                          
  _create_callbacks=         _run_validate_callbacks    attribute_method_matchers?   persistable_attribute_names              
  _create_callbacks?         _run_validation_callbacks  cache_timestamp_format       pluralize_table_names                    
  _destroy_callbacks         _save_callbacks            cache_timestamp_format?      pluralize_table_names?                   
  _destroy_callbacks=        _save_callbacks=           column_for_attribute         primary_key_prefix_type                  
  _destroy_callbacks?        _save_callbacks?           default_connection_handler   raise_in_transactional_callbacks         
  _find_callbacks            _touch_callbacks           default_connection_handler?  record_timestamps                        
  _find_callbacks=           _touch_callbacks=          default_scopes               record_timestamps=                       
  _find_callbacks?           _touch_callbacks?          default_timezone             record_timestamps?                       
  _initialize_callbacks      _update_callbacks          defined_enums                schema_format                            
  _initialize_callbacks=     _update_callbacks=         defined_enums=               skip_time_zone_conversion_for_attributes 
  _initialize_callbacks?     _update_callbacks?         defined_enums?               skip_time_zone_conversion_for_attributes?
  _reflections               _validate_callbacks        dump_schema_after_migration  store_full_sti_class                     
  _reflections=              _validate_callbacks=       find_by_statement_cache      store_full_sti_class?                    
  _reflections?              _validate_callbacks?       find_by_statement_cache=     table_name_prefix                        
  _rollback_callbacks        _validation_callbacks      find_by_statement_cache?     table_name_prefix?                       
  _rollback_callbacks=       _validation_callbacks=     include_root_in_json         table_name_suffix                        
  _rollback_callbacks?       _validation_callbacks?     include_root_in_json=        table_name_suffix?                       
  _run_commit_callbacks      _validators                include_root_in_json?        time_zone_aware_attributes               
  _run_create_callbacks      _validators=               lock_optimistically          timestamped_migrations                   
  _run_destroy_callbacks     _validators?               lock_optimistically?         type_for_attribute                       
  _run_find_callbacks        aggregate_reflections      logger                       validation_context                       
  _run_initialize_callbacks  aggregate_reflections=     model_name                   validation_context=                      
[1m[1;34m#<#<Class:0x00000003c40038>:0x00000003c400b0>#methods[0m[0m: 
  created_at                     mode                   reset_x!                      speed_before_type_cast       x_before_type_cast
  created_at=                    mode=                  reset_y!                      speed_came_from_user?        x_came_from_user? 
  created_at?                    mode?                  reset_z!                      speed_change                 x_change          
  created_at_before_type_cast    mode_before_type_cast  restore_created_at!           speed_changed?               x_changed?        
  created_at_came_from_user?     mode_came_from_user?   restore_id!                   speed_was                    x_was             
  created_at_change              mode_change            restore_message_type!         speed_will_change!           x_will_change!    
  created_at_changed?            mode_changed?          restore_mode!                 updated_at                   y                 
  created_at_was                 mode_was               restore_pin!                  updated_at=                  y=                
  created_at_will_change!        mode_will_change!      restore_sequence_id!          updated_at?                  y?                
  id                             pin                    restore_speed!                updated_at_before_type_cast  y_before_type_cast
  id=                            pin=                   restore_updated_at!           updated_at_came_from_user?   y_came_from_user? 
  id?                            pin?                   restore_value!                updated_at_change            y_change          
  id_before_type_cast            pin_before_type_cast   restore_x!                    updated_at_changed?          y_changed?        
  id_came_from_user?             pin_came_from_user?    restore_y!                    updated_at_was               y_was             
  id_change                      pin_change             restore_z!                    updated_at_will_change!      y_will_change!    
  id_changed?                    pin_changed?           sequence_id                   value                        z                 
  id_was                         pin_was                sequence_id=                  value=                       z=                
  id_will_change!                pin_will_change!       sequence_id?                  value?                       z?                
  message_type                   reset_created_at!      sequence_id_before_type_cast  value_before_type_cast       z_before_type_cast
  message_type=                  reset_id!              sequence_id_came_from_user?   value_came_from_user?        z_came_from_user? 
  message_type?                  reset_message_type!    sequence_id_change            value_change                 z_change          
  message_type_before_type_cast  reset_mode!            sequence_id_changed?          value_changed?               z_changed?        
  message_type_came_from_user?   reset_pin!             sequence_id_was               value_was                    z_was             
  message_type_change            reset_sequence_id!     sequence_id_will_change!      value_will_change!           z_will_change!    
  message_type_changed?          reset_speed!           speed                         x                          
  message_type_was               reset_updated_at!      speed=                        x=                         
  message_type_will_change!      reset_value!           speed?                        x?                         
[1m[1;34mStep::GeneratedAssociationMethods#methods[0m[0m: build_sequence  create_sequence  create_sequence!  sequence  sequence=
[1m[1;34mStep#methods[0m[0m: 
  autosave_associated_records_for_sequence  bot   command   execute        move_relative  unknown
  belongs_to_counter_cache_after_update     bot=  command=  move_absolute  pin_write      wait   
[1m[1;34minstance variables[0m[0m: 
  [0;34m@_start_transaction_state[0m  [0;34m@attributes[0m          [0;34m@destroyed[0m                 [0;34m@new_record[0m               [0;34m@reflects_state[0m   
  [0;34m@aggregation_cache[0m         [0;34m@changed_attributes[0m  [0;34m@destroyed_by_association[0m  [0;34m@original_raw_attributes[0m  [0;34m@transaction_state[0m
  [0;34m@association_cache[0m         [0;34m@command[0m             [0;34m@marked_for_destruction[0m    [0;34m@readonly[0m                 [0;34m@txn[0m              
[1m[1;34mclass variables[0m[0m: 
  [1;34m@@configurations[0m    [1;34m@@dump_schema_after_migration[0m  [1;34m@@maintain_test_schema[0m     [1;34m@@raise_in_transactional_callbacks[0m  [1;34m@@time_zone_aware_attributes[0m
  [1;34m@@default_timezone[0m  [1;34m@@logger[0m                       [1;34m@@primary_key_prefix_type[0m  [1;34m@@schema_format[0m                     [1;34m@@timestamped_migrations[0m    
[1m[1;34mlocals[0m[0m: _  __  _dir_  _ex_  _file_  _in_  _out_  _pry_  [0;33mbot[0m
