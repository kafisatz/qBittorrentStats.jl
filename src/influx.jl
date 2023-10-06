export reset_bucket
function reset_bucket(isettings,a_random_bucket_name) 
    buckets,_ = get_buckets(isettings)
    if in(a_random_bucket_name,buckets)
        delete_bucket(isettings,a_random_bucket_name);
    end
    create_bucket(isettings,a_random_bucket_name);
    return nothing 
end