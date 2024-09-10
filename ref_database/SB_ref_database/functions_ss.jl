global tab                  = "    "

struct ModelJSON
    name            :: String
    abbrev          :: String
    endmembers      :: Dict{String, Vector{String}}
    margules        :: Dict{String, Float64}
    van_laar        :: Vector{Float64}
end

function retrieve_site_cmp(ss, i)

    em          = String.(keys(ss[i].endmembers))
    n_em        = length(em)

    fml         = ss[i].endmembers[em[1]][2]

    matches     = eachmatch(r"\[([^\[\]]+)\]", fml)
    contents    = [m.captures[1] for m in matches]

    n_sf        = length(contents)

    mul         = zeros(Float64, n_sf)
    site_cmp    = zeros(Float64, n_sf,n_el, n_em)

    for j=1:n_em
        fml         = ss[i].endmembers[em[j]][2]
        matches     = eachmatch(r"\[([^\[\]]+)\]", fml)
        contents    = [m.captures[1] for m in matches]

        for k=1:length(contents)
            matches = eachmatch(r"_(\d+)", contents[k])
            n_atoms = [parse(Int, m.captures[1]) for m in matches]
            matches = eachmatch(r"[A-Za-z]+", contents[k])
            elements= [m.match for m in matches]
            mul[k]  = sum(n_atoms)

            if length(n_atoms) == 1
                id              = findfirst(elems .== elements[1])
                site_cmp[k,id, j] = Float64(n_atoms[1])
            else
                for l=1:length(n_atoms)
                    id              = findfirst(elems .== elements[l])
                    site_cmp[k,id, j] = Float64(n_atoms[l])
                end
            end
        end
    end


    return mul, site_cmp
end

function get_sb_gss_init_function(sb_ver,ss)
    sb_gss_init_function = ""

    n_ss = length(ss)
    for i = 1:n_ss

        mul, site_cmp = retrieve_site_cmp(ss, i)

        W   = [ ss[i].margules[j] for j in  keys(ss[i].margules)]

        v   = [ ss[i].van_laar[j] for j in  keys(ss[i].van_laar)]

        em  = [ ss[i].endmembers[j][1] for j in  keys(ss[i].endmembers)]

        println(mul, site_cmp, W, v, em)

        sym = 1
        if ~isempty(v)
            sym = 0
        end
        
        sb_gss_init_function *= "/**\n"
        sb_gss_init_function *= "    allocate memory for $(sb_ver)_$(ss[i].abbrev)\n"
        sb_gss_init_function *= "*/\n"
        sb_gss_init_function *= "SS_ref SB_G_SS_$(sb_ver)_$(ss[i].abbrev)_init_function(SS_ref SS_ref_db,  global_variable gv){\n\n"
        sb_gss_init_function *= "    SS_ref_db.sb        = 1;\n"
        sb_gss_init_function *= "    SS_ref_db.symmetry  = $sym;\n"
        sb_gss_init_function *= "    SS_ref_db.n_em      = $(length(em));\n"
        sb_gss_init_function *= "    SS_ref_db.n_sf      = $(length(mul));\n"
        sb_gss_init_function *= "    SS_ref_db.n_W       = $(length(W));\n"
        if sym == 0
            sb_gss_init_function *= "    SS_ref_db.n_v       = $(length(v));\n"
        end
        sb_gss_init_function *= "\n"
        sb_gss_init_function *= "     return SS_ref_db;\n"
        sb_gss_init_function *= "}\n\n"
    end


    sb_gss_init_function *= "void SB_SS_init_sb11(	    SS_init_type 		*SS_init,\n"
    sb_gss_init_function *= "                            global_variable 	 gv				){\n\n"
    sb_gss_init_function *= "$(tab)for (int iss = 0; iss < gv.len_ss; iss++){\n"
    for i = 1:n_ss
        if i == 1
            sb_gss_init_function *= "$(tab)$(tab)if      (strcmp( gv.SS_list[iss], \"$(ss[i].abbrev)\")  == 0 ){\n"
            sb_gss_init_function *= "$(tab)$(tab)$(tab)SS_init[iss]  = SB_G_SS_$(sb_ver)_$(ss[i].abbrev)_init_function; 		}\n"
        else
            sb_gss_init_function *= "$(tab)$(tab)else if (strcmp( gv.SS_list[iss], \"$(ss[i].abbrev)\")  == 0 ){\n"
            sb_gss_init_function *= "$(tab)$(tab)$(tab)SS_init[iss]  = SB_G_SS_$(sb_ver)_$(ss[i].abbrev)_init_function; 		}\n"
        end
    end
    sb_gss_init_function *= "$(tab)$(tab)else{\n"
    sb_gss_init_function *= "$(tab)$(tab)$(tab)printf(\"\\nsolid solution '%s' is not in the database, cannot be initiated\\n\", gv.SS_list[iss]);\n"
    sb_gss_init_function *= "$(tab)$(tab)}\n"
    sb_gss_init_function *= "$(tab)}\n"
    sb_gss_init_function *= "}\n"
    return sb_gss_init_function
end
    
function generate_C_files(sb_ver,ss)

    sb_gss_init_function = get_sb_gss_init_function(sb_ver,ss)

    return sb_gss_init_function
end


# SS_ref G_SS_um_chl_init_function(SS_ref SS_ref_db,  global_variable gv){
    
#     SS_ref_db.is_liq    = 0;
#     SS_ref_db.symmetry  = 1;
#     SS_ref_db.n_sf      = 11;
#     SS_ref_db.n_em      = 7;
#     SS_ref_db.n_w       = 21;
#     SS_ref_db.n_xeos    = 6;
    
#     return SS_ref_db;
# }