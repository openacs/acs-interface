-- 
-- packages/acs-interfaces/sql/acs-interface-create.sql
--
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

create sequence acs_interface_all_id_sequence;

create table acs_interfaces (
    interface_id	    integer	
	constraint acs_inter_int_id_pk primary key,
    interface_name	    varchar(40)
	constraint acs_inter_int_name_nn not null,
    programming_language    varchar(50)
	constraint acs_inter_prog_lang_nn not null,
    enabled_p		    boolean default 't'
	constraint acs_inter_enabled_p_nn not null,
    description		    text
	constraint acs_inter_desc_nn not null,
    creation_date	    timestamp,
    creation_user	    integer
	constraint acs_inter_creation_user_fk references users,
    creation_ip		    varchar(50),
    constraint acs_inter_name_lang_un unique (interface_name, programming_language)
);


comment on table acs_interfaces is 'An interface is a name for a set of methods.  The methods'' 
definitions are in acs_interface_methods table.  Interfaces provide a facility to 
add functionality to an object without adding to or changing the internal structure. When 
an object type implements an interface, the object type agrees, contractual level, to 
implement those methods according to the interface specification. The implementation of
those methods is dependent upon the language. In Oracle PL/SQL environment, the methods
are defined and declared in a package with the same name as the object type.';

comment on column acs_interfaces.programming_language is 'Programming Languages are PL/SQL, TCL, and JAVA';
comment on column acs_interfaces.description is 'The description of the purpose and utility for the interface';
comment on column acs_interfaces.enabled_p is 'Is the interface being used?';

create table acs_interface_methods (
    method_id		integer
	constraint acs_int_met_method_id_pk primary key,
    interface_id		integer
	constraint acs_int_met_interface_id_fk references acs_interfaces(interface_id) on delete cascade
	constraint acs_int_met_interface_id_nn not null,
    method_name		varchar(100)
	constraint acs_int_met_interface_name_nn not null,
	-- call type is either function  or procedure
    method_type		varchar(10) default 'procedure'
	constraint acs_int_met_method_type_ck check (method_type in ('function', 'procedure')),
    return_type 	varchar(50),
    method_desc		text
);

comment on table acs_interface_methods is 'Definition of interfaces'' methods';

comment on column acs_interface_methods.method_name is 'The name of the method';

comment on column acs_interface_methods.method_type is 'Is the method a function or procedure';

comment on column acs_interface_methods.return_type is 'The return type for a function.';

comment on column acs_interface_methods.method_desc is 'description of the method';

create table acs_interface_method_params (
    method_id 		integer
	constraint aimp_method_id_fk references acs_interface_methods(method_id) on delete cascade
	constraint aimp_method_id_nn not null,
    param_name		varchar(100)
	constraint aimp_param_name_nn not null,
    param_type		varchar(50)
	constraint aimp_param_type_nn not null,
    -- parameter pass by reference
    param_ref_p		boolean default 'f',
    param_desc		text,
    -- extra information about the parameter
    param_spec		text,
    required_p		boolean default 't',
    pos			integer 
	constraint aimp_param_order_nn not null,
    constraint aimp_meth_pos_pk primary key (method_id, pos)
);

comment on table acs_interface_method_params is 'Stores the methods'' parameter definition';

comment on column acs_interface_method_params.param_type is 'what is the data type of 
    the parameter';

comment on column acs_interface_method_params.param_ref_p is 'Is this param pass by value or  
    reference? For Oracle, it is IN or IN OUT, respectively.';

comment on column acs_interface_method_params.required_p is 'Is the parameter required?';

comment on column acs_interface_method_params.param_spec is 'Extra information about the parameter. For example
in PL/SQL it could include optimization options (i.e. NOCOPY).';

comment on column acs_interface_method_params.pos is 'The position of the parameter within the 
    method''s parameter definition.';

comment on column acs_interface_method_params.param_desc is 'The description of the parameter';

create table acs_interface_obj_type_map (
    interface_id	integer 
	constraint acs_inter_map_int_id_fk references acs_interfaces on delete cascade
	constraint acs_inter_map_int_id_nn not null,
    object_type		varchar(100)
	constraint acs_inter_map_obj_type_fk references acs_object_types on delete cascade
	constraint acs_inter_map_obj_type_nn not null,
    -- another object type may provide the implementation
    object_type_impl_interface varchar(30),
    constraint acs_inter_map_int_obj_un unique (interface_id, object_type)
);

comment on table acs_interface_obj_type_map is 'Mapping of acs_interfaces with object types';
comment on column acs_interface_obj_type_map.object_type_impl_interface is 'This object type 
provides the implementation details for the object type';






