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
    interface_name	    varchar2(40)
	constraint acs_inter_int_name_nn not null,
    programming_language    varchar2(50)
	constraint acs_inter_prog_lang_nn not null,
    description		    varchar2(4000)
	constraint acs_inter_desc_nn not null,
    enabled_p		    char(1) default 't'
	constraint acs_inter_enabled_p_nn not null
	constraint acs_inter_enabled_p_ck check (enabled_p in ('t','f')),
    creation_user	    integer
	constraint acs_inter_creation_user_fk references users,
    creation_date	    date,
    creation_ip		    varchar2(50),
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
    method_name		varchar2(100)
	constraint acs_int_met_interface_name_nn not null,
	-- call type is either function  or procedure
    method_type		varchar2(10) default 'procedure'
	constraint acs_int_met_method_type_ck check (method_type in ('function', 'procedure')),
    return_type 	varchar2(50),
    method_desc		varchar2(4000)
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
    param_name		varchar2(100)
	constraint aimp_param_name_nn not null,
    param_type		varchar2(50)
	constraint aimp_param_type_nn not null,
    -- parameter pass by reference
    param_ref_p		char(1) default 'f'
	constraint aimp_param_ref_p_ck check (param_ref_p in ('t','f')),
    param_desc		varchar2(4000),
    -- extra information about the parameter
    param_spec		varchar2(4000),
    required_p		char(1) default 't'
	constraint aimp_param_required_p_ck check (required_p in ('t','f')),
    position		integer 
	constraint aimp_param_order_nn not null,
    constraint aimp_meth_pos_pk primary key (method_id, position)
);

comment on table acs_interface_method_params is 'Stores the methods'' parameter definition';

comment on column acs_interface_method_params.param_type is 'what is the data type of 
    the parameter';

comment on column acs_interface_method_params.param_ref_p is 'Is this param pass by value or  
    reference? For Oracle, it is IN or IN OUT, respectively.';

comment on column acs_interface_method_params.required_p is 'Is the parameter required?';

comment on column acs_interface_method_params.param_spec is 'Extra information about the parameter. For example
in PL/SQL it could include optimization options (i.e. NOCOPY).';

comment on column acs_interface_method_params.position is 'The position of the parameter within the 
    method''s parameter definition.';

comment on column acs_interface_method_params.param_desc is 'The description of the parameter';

create table acs_interface_obj_type_map (
    interface_id	integer 
	constraint acs_inter_map_int_id_fk references acs_interfaces on delete cascade
	constraint acs_inter_map_int_id_nn not null,
    object_type		varchar2(100)
	constraint acs_inter_map_obj_type_fk references acs_object_types on delete cascade
	constraint acs_inter_map_obj_type_nn not null,
    -- another object type may provide the implementation
    object_type_impl_interface varchar2(30),
    constraint acs_inter_map_int_obj_un unique (interface_id, object_type)
);

comment on table acs_interface_obj_type_map is 'Mapping of acs_interfaces with object types';
comment on column acs_interface_obj_type_map.object_type_impl_interface is 'This object type 
provides the implementation details for the object type';
    
-- The acs_interface package has methods to add interface, associate methods with interfaces,
-- and associate parameters with methods
create or replace package acs_interface 
as 
    function new (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	enabled_p		in acs_interfaces.enabled_p%TYPE,
	description		in acs_interfaces.description%TYPE,
	creation_date		in acs_interfaces.creation_date%TYPE default sysdate,
	creation_user		in acs_interfaces.creation_user%TYPE default null,
	creation_ip		in acs_interfaces.creation_ip%TYPE default null
    ) return acs_interfaces.interface_id%TYPE;

    procedure del (
	interface_id		in acs_interfaces.interface_id%TYPE
    );
    procedure del (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE
    );
    procedure assoc_obj_type_with_interface (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE,
	object_type_imp		in varchar2 default null
    );

    procedure remove_obj_type_impl (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    );

    function get_interface_id (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE
    ) return acs_interfaces.interface_id%TYPE;

    function add_method (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	method_name		in acs_interface_methods.method_name%TYPE,
	method_type		in acs_interface_methods.method_type%TYPE,
	return_type		in acs_interface_methods.return_type%TYPE,
	method_desc		in acs_interface_methods.method_desc%TYPE
    ) return acs_interface_methods.method_id%TYPE;
    
    procedure add_param_to_method (
	method_id		in acs_interface_method_params.method_id%TYPE,
	param_name		in acs_interface_method_params.param_name%TYPE,
	param_type		in acs_interface_method_params.param_type%TYPE,
	position		in acs_interface_method_params.position%TYPE default null,
	param_desc		in acs_interface_method_params.param_desc%TYPE default null,
	param_spec		in acs_interface_method_params.param_spec%TYPE default null,
	param_ref_p		in acs_interface_method_params.param_ref_p%TYPE default 'f',
	required_p		in acs_interface_method_params.required_p%TYPE default 't'
    );

    procedure remove_method (
	method_id		in acs_interface_methods.method_id%TYPE
    );
    
    procedure remove_param_from_method (
	method_id		in acs_interface_methods.method_id%TYPE,
	position		in acs_interface_method_params.position%TYPE
    );

    function object_type_implement_p (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    ) return char;

    function object_id_implement_p (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_id		in acs_objects.object_id%TYPE
    ) return char;

    -- returns the object type that provides the implementation for passed in 
    -- object type, if none specified then return the object type
    function obj_provide_implement (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    ) return varchar2;	

end acs_interface;
/


create or replace package body acs_interface 
as 
    function new (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	enabled_p		in acs_interfaces.enabled_p%TYPE,
	description		in acs_interfaces.description%TYPE,
	creation_date		in acs_interfaces.creation_date%TYPE default sysdate,
	creation_user		in acs_interfaces.creation_user%TYPE default null,
	creation_ip		in acs_interfaces.creation_ip%TYPE default null
    ) return acs_interfaces.interface_id%TYPE
    is
	v_interface_id	    integer;
    begin

	select acs_interface_all_id_sequence.nextval into v_interface_id
	from dual;

	insert into acs_interfaces (
	    interface_id,
	    interface_name,
	    programming_language,
	    enabled_p,
	    description,
	    creation_date,
	    creation_user,
	    creation_ip
	) values (
	    v_interface_id,
	    interface_name,
	    programming_language,
	    enabled_p,
	    description,
	    creation_date,
	    creation_user,
	    creation_ip
	);
	return v_interface_id;
    end new;
	
    procedure del (
	interface_id	    in acs_interfaces.interface_id%TYPE
    ) 
    is 
    begin

	delete from acs_interfaces
	where interface_id = acs_interface.del.interface_id;
    end del;   

    procedure del (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE
    )
    is
	v_interface_id	    integer;
    begin
	delete from acs_interfaces
	where interface_name = acs_interface.del.interface_name 
	and   programming_language = acs_interface.del.programming_language;

	return;

    end del;	

    procedure assoc_obj_type_with_interface (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	    in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE,
	object_type_imp		in varchar2 default null
    ) 
    is
	v_interface_id	    integer;
    begin

	v_interface_id := acs_interface.get_interface_id (
	    interface_name	    => interface_name,
	    programming_language    => programming_language
	);

	insert into acs_interface_obj_type_map (
	    interface_id,
	    object_type,
	    object_type_impl_interface
	) values (
	    v_interface_id,
	    object_type,
	    object_type_imp
	);
    end assoc_obj_type_with_interface;

    procedure remove_obj_type_impl (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    )
    is
    begin
	delete from acs_interface_obj_type_map 
	where object_type = remove_obj_type_impl.object_type 
	and interface_id = get_interface_id (interface_name, programming_language);
    end;


    function get_interface_id (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE
    ) return acs_interfaces.interface_id%TYPE
    is
	v_interface_id	    integer;
    begin
	select interface_id into v_interface_id
	from acs_interfaces
	where interface_name = acs_interface.get_interface_id.interface_name
	and   programming_language = acs_interface.get_interface_id.programming_language;

	return v_interface_id;

	exception 
	    when no_data_found then
		raise_application_error(-20001, 'Interface for '|| programming_language ||' '||interface_name|| 'does not exist!');

    end get_interface_id;	

    function add_method (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	method_name		in acs_interface_methods.method_name%TYPE,
	method_type		in acs_interface_methods.method_type%TYPE,
	return_type		in acs_interface_methods.return_type%TYPE,	
	method_desc		in acs_interface_methods.method_desc%TYPE default null
    ) return acs_interface_methods.method_id%TYPE
    is
	v_interface_id		integer;
	v_method_id		integer;
    begin

	v_interface_id := acs_interface.get_interface_id (
	    interface_name	    => interface_name,
	    programming_language    => programming_language);

	select acs_interface_all_id_sequence.nextval into v_method_id 
	from dual;
	
	insert into acs_interface_methods (
	    interface_id,
	    method_id,
	    method_name,
	    method_type,
	    return_type,
	    method_desc
	) values (
	    v_interface_id,
	    v_method_id,
	    method_name,
	    method_type,
	    return_type,
	    method_desc
	);
	return v_method_id;
    end add_method;
    
    -- position is null indicates the last parameter
    -- if not null, shift parameters to the right and insert
    procedure add_param_to_method (
	method_id	    in acs_interface_method_params.method_id%TYPE   ,
	param_name	    in acs_interface_method_params.param_name%TYPE  ,
	param_type	    in acs_interface_method_params.param_type%TYPE  ,
	position	    in acs_interface_method_params.position%TYPE    default null,
	param_desc	    in acs_interface_method_params.param_desc%TYPE  default null,
	param_spec	    in acs_interface_method_params.param_spec%TYPE  default null,
	param_ref_p	    in acs_interface_method_params.param_ref_p%TYPE default 'f',
	required_p	    in acs_interface_method_params.required_p%TYPE  default 't'
    ) 
    is
	v_isnull	integer;
    begin	
	select decode (position,null,1,0) into v_isnull 
	from dual;


	if v_isnull = 0 then
	    -- if the position is not null
	    -- Increment the other params' positions whose
	    -- placement is at the specified 'position' or higher. 
	    update acs_interface_method_params
		set position = position + 1
	    where method_id >= acs_interface.add_param_to_method.param_name;
	    
	    -- insert the new parameter at the specified 'position'
	    insert into acs_interface_method_params (
		method_id   ,
		param_name  , 
		param_type  ,
		param_ref_p ,
		param_desc  ,
		param_spec  ,
		position    ,
		required_p
	    ) values (
		acs_interface.add_param_to_method.method_id	,
		acs_interface.add_param_to_method.param_name	,	
		acs_interface.add_param_to_method.param_type	,
		acs_interface.add_param_to_method.param_ref_p	,	
		acs_interface.add_param_to_method.param_desc	,
		acs_interface.add_param_to_method.param_spec	,
		acs_interface.add_param_to_method.position	,
		acs_interface.add_param_to_method.required_p
	    );
	else 
	-- Position was not specified, place the new parameter at the end of the parameter list.

	    insert into acs_interface_method_params (
		method_id   ,
		param_name  ,
		param_type  ,
		param_ref_p ,
		param_desc  ,
		param_spec  ,
		required_p  ,
		position
	    ) select acs_interface.add_param_to_method.method_id,
		acs_interface.add_param_to_method.param_name	,
		acs_interface.add_param_to_method.param_type	,
		acs_interface.add_param_to_method.param_ref_p	,	
		acs_interface.add_param_to_method.param_desc	,
		acs_interface.add_param_to_method.param_spec	,
		acs_interface.add_param_to_method.required_p	,
		decode(max(position),null,0,max(position))+1
	     from acs_interface_method_params
	     where method_id = acs_interface.add_param_to_method.method_id;
	end if;	
    end add_param_to_method;

    -- removes methods from the interface
    procedure remove_method (
	method_id	    in acs_interface_methods.method_id%TYPE
    )
    is 
    begin
	delete from acs_interface_methods 
	where method_id = acs_interface.remove_method.method_id;
    end remove_method;
    
    procedure remove_param_from_method (
	method_id	    in acs_interface_methods.method_id%TYPE,
	position	    in acs_interface_method_params.position%TYPE
    )
    is
    begin
	delete from acs_interface_method_params
	where method_id = acs_interface.remove_param_from_method.method_id
	and   position = acs_interface.remove_param_from_method.position;
    end remove_param_from_method;

    function object_type_implement_p (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    ) return char
    is
	v_implement_p		char(1);
    begin
	select decode (count(*),0,'f','t') into v_implement_p
	from acs_interface_obj_type_map aiopm,
	     acs_interfaces ai
	where aiopm.object_type = acs_interface.object_type_implement_p.object_type 
	and aiopm.interface_id = ai.interface_id 
	and ai.interface_name = acs_interface.object_type_implement_p.interface_name
	and ai.programming_language = acs_interface.object_type_implement_p.programming_language;

	return v_implement_p;
    end object_type_implement_p;

    function object_id_implement_p (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_id		in acs_objects.object_id%TYPE
    ) return char	
    is
	v_implement_p	    char(1);
    begin
	select decode (count(*),0,'f','t') into v_implement_p
	from acs_interface_obj_type_map aiopm,
	     acs_interfaces ai,
	     acs_objects ao
	where ao.object_id = object_id 
	and aiopm.object_type = ao.object_type
	and aiopm.interface_id = ai.interface_id 
	and ai.interface_name = acs_interface.object_id_implement_p.interface_name
	and ai.programming_language = acs_interface.object_id_implement_p.programming_language;

	return v_implement_p;

    end object_id_implement_p;	

    function obj_provide_implement (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE,
	object_type		in acs_object_types.object_type%TYPE
    ) return varchar2
    is
	object_type_imp		varchar2(30);
    begin

	object_type_imp := object_type;

	for obj_type_impl_row in (select object_type_impl_interface 
			    from acs_interface_obj_type_map
			    where interface_id = 
				  acs_interface.get_interface_id(interface_name,programming_language)
			    and   object_type = acs_interface.obj_provide_implement.object_type) loop
	    object_type_imp := obj_type_impl_row.object_type_impl_interface;
	end loop;

	return object_type_imp;
    end;
end acs_interface;
/







