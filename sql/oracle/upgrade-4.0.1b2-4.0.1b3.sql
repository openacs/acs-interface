-- 
-- packages/acs-interfaces/sql/upgrade-4.0.1b2-4.0.1b3.sql
--
-- @author khy@arsdigita.com
-- @creation-date 2000-01-19
-- @cvs-id $id$
--


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
	
    procedure delete (
	interface_id	    in acs_interfaces.interface_id%TYPE
    ) 
    is 
    begin

	delete from acs_interfaces
	where interface_id = acs_interface.delete.interface_id;
    end delete;   

    procedure delete (
	interface_name		in acs_interfaces.interface_name%TYPE,
	programming_language	in acs_interfaces.programming_language%TYPE
    )
    is
	v_interface_id	    integer;
    begin
	delete from acs_interfaces
	where interface_name = acs_interface.delete.interface_name 
	and   programming_language = acs_interface.delete.programming_language;

	return;

    end delete;	

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