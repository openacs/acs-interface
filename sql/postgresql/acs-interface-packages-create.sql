-- 
-- packages/acs-interfaces/sql/acs-interface-create.sql
--
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--
    
-- The acs_interface package has methods to add interface, associate methods with interfaces,
-- and associate parameters with methods

create function acs_interface__new(varchar,varchar,boolean,text,timestamp,integer,varchar) 
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_enabled_p			alias for $3;
    p_description		alias for $4;
    p_creation_date		alias for $5; -- default sysdate
    p_creation_user		alias for $6; -- default null
    p_creation_ip		alias for $7; -- default null
    v_interface_id		integer;
begin

    select nextval(''acs_interface_all_id_sequence'') into v_interface_id;

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
	p_interface_name,
	p_programming_language,
	p_enabled_p,
	p_description,
	p_creation_date,
	p_creation_user,
	p_creation_ip
    );

    return v_interface_id;

end;' language 'plpgsql';


create function acs_interface__delete(integer)
returns integer as '
declare
    p_interface_id	    alias for $1;
begin
    delete from acs_interfaces
    where interface_id = p_interface_id;

    return 0; 
end;' language 'plpgsql';



create function acs_interface__delete(varchar,varchar)
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    v_interface_id		integer;
begin
    delete from acs_interfaces
    where interface_name = p_interface_name 
    and   programming_language = p_programming_language;

    return 0; 
end;' language 'plpgsql';


create function acs_interface__assoc_obj_type_with_interface (varchar,varchar,varchar,varchar)
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_object_type		alias for $3;
    p_object_type_imp		alias for $4; -- default null
    v_interface_id		integer;
begin

    v_interface_id := acs_interface__get_interface_id (
	    p_interface_name
	    p_programming_language
    );

    insert into acs_interface_obj_type_map (
        interface_id,
	object_type,
	object_type_impl_interface
    ) values (
        v_interface_id,
	p_object_type,
	p_object_type_imp
    );

    return 0; 
end;' language 'plpgsql';



create function acs_interface__remove_obj_type_impl (varchar,varchar,varchar)
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_object_type		alias for $3;
begin
    delete from acs_interface_obj_type_map 
    where object_type = p_object_type 
    and interface_id = acs_interface__get_interface_id (p_interface_name, p_programming_language);

    return 0; 
end;' language 'plpgsql';



create function acs_interface__get_interface_id (varchar,varchar)
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    v_interface_id		integer;
begin
    select interface_id into v_interface_id
    from acs_interfaces
    where interface_name = p_interface_name
    and   programming_language = p_programming_language;


    if not found then
        raise exception ''Interface % for % does not exist.'', p_interface_name, p_programming_language;
    end if;


    return v_interface_id;

end;' language 'plpgsql';
	

create function acs_interface__add_method (varchar,varchar,varchar,varchar,varchar,text)
returns integer as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_method_name		alias for $3;
    p_method_type		alias for $4;
    p_return_type		alias for $5;
    p_method_desc		alias for $6; -- default null
    v_interface_id		integer;
    v_method_id			integer;
begin

    v_interface_id := acs_interface__get_interface_id (p_interface_name,p_programming_language);

    select nextval(acs_interface_all_id_sequence) into v_method_id;

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
	p_method_name,
	p_method_type,
	p_return_type,
	p_method_desc
    );

    return v_method_id;


end;' language 'plpgsql';

    
    -- position is null indicates the last parameter
    -- if not null, shift parameters to the right and insert
create function acs_interface__add_param_to_method (integer,varchar,varchar,integer,text,text,boolean,boolean)
returns integer as '
declare
    p_method_id			alias for $1;
    p_param_name		alias for $2;
    p_param_type		alias for $2;
    p_pos			alias for $2; -- default null
    p_param_desc		alias for $2; -- default null
    p_param_spec		alias for $2; -- default null
    p_param_ref_p		alias for $2; -- default f
    p_required_p		alias for $2; -- default t
    v_isnull			integer;
begin
    select (case when p_pos is null then 1 else 0 end) into v_isnull;

    if v_isnull = 0 then
    -- if the position is not null
    -- Increment the other params positions whose
    -- placement is at the specified position or higher.
-- HERE
--    update acs_interface_method_params
--    set pos = pos + 1
--    where p_method_id >= p_param_name;
	    
	    -- insert the new parameter at the specified position
	    insert into acs_interface_method_params (
		method_id,
		param_name, 
		param_type,
		param_ref_p,
		param_desc,
		param_spec,
		pos,
		required_p
	    ) values (
		p_method_id,
		p_param_name,	
		p_param_type,
		p_param_ref_p,	
		p_param_desc,
		p_param_spec,
		p_pos,
		p_required_p
	    );
	else 
	-- Position was not specified, place the new parameter at the end of the parameter list.

	    insert into acs_interface_method_params (
		method_id,
		param_name,
		param_type,
		param_ref_p,
		param_desc,
		param_spec,
		required_p,
		pos
	    ) select p_method_id,
		p_param_name,
		p_param_type,
		p_param_ref_p,	
		p_param_desc,
		p_param_spec,
		p_required_p,
		(case when max(pos) is null then 0 else max(pos))+1 end)
	     from acs_interface_method_params
	     where method_id = p_method_id;
	end if;	

    return 0; 
end;' language 'plpgsql';






-- removes methods from the interface
create function acs_interface__remove_method (integer)
returns integer as '
declare
    p_method_id		alias for $1;
begin
    delete from acs_interface_methods 
    where method_id = p_method_id;

    return 0; 
end;' language 'plpgsql';


create function acs_interface__remove_param_from_method (integer,integer)
returns integer as '
declare
    p_method_id		alias for $1;
    p_pos		alias for $2;
begin
    delete from acs_interface_method_params
    where method_id = p_method_id
    and   pos = p_pos;

    return 0; 
end;' language 'plpgsql';




create function acs_interface__object_type_implement_p (varchar,varchar,varchar)
returns boolean as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_object_type		alias for $3;
    v_implement_p		boolean;
begin

    select (case when count(*)=0 then ''f'' else ''t'' end) into v_implement_p
    from acs_interface_obj_type_map aiopm,
	 acs_interfaces ai
    where aiopm.object_type = p_object_type 
        and aiopm.interface_id = ai.interface_id 
	and ai.interface_name = p_interface_name
	and ai.programming_language = p_programming_language;

	return v_implement_p;

end;' language 'plpgsql';




create function acs_interface__object_id_implement_p (varchar,varchar,varchar)
returns boolean as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_object_id			alias for $3;
    v_implement_p		boolean;
begin

    select (case when count(*)=0 then ''f'' else ''t'' end) into v_implement_p
    from acs_interface_obj_type_map aiopm,
	 acs_interfaces ai,
	 acs_objects ao
    where ao.object_id = object_id 
	 and aiopm.object_type = ao.object_type
	 and aiopm.interface_id = ai.interface_id 
	 and ai.interface_name = p_interface_name
	 and ai.programming_language = p_programming_language;

    return v_implement_p;

end;' language 'plpgsql';


create function acs_interface__obj_provide_implement (varchar,varchar,varchar)
returns varchar as '
declare
    p_interface_name		alias for $1;
    p_programming_language	alias for $2;
    p_object_type		alias for $3;
    v_object_type_imp		varchar(30);
begin

	v_object_type_imp := p_object_type;

        for v_obj_type_impl_row in (select object_type_impl_interface 
                            from acs_interface_obj_type_map
                            where interface_id =acs_interface__get_interface_id(interface_name,programming_language)
                            and   object_type = p_object_type) loop
            v_object_type_imp := obj_type_impl_row.object_type_impl_interface;
        end loop;


    return v_object_type_imp;
end;' language 'plpgsql';

