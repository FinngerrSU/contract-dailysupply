module dailysupply::dailySupply;

    use std::string::{ Self,String};
    use sui::package;
    use sui::random::{Self, Random};
    use sui::display;
    use sui::event;
   


    const EInvalidIndex:u64=0;
    const InvalidRegistrty:u64=1;
    

public struct DAILYSUPPLY has drop{}
    
public struct Entertain has key, store {
        id: UID,
        image_url: String,
        name: String,
        
    }

public struct Template has store, copy, drop {
        url: String,
        name: String,
        
    }

public struct Registry has key {
        id: UID,
        templates: vector<Template>,
        year: u64
        
    }

public struct DailySpecial has key {
        id: UID,
        current: Template, 
    }
public struct AdminCap has key, store { id: UID }

///--Event---
public struct Minted has copy, drop {
    id:ID,
    name: String,
    
}

fun init(otw:DAILYSUPPLY, ctx: &mut TxContext) {
        
       let publisher = package::claim(otw, ctx);

        
        let mut keys = vector::empty();
        vector::push_back(&mut keys, string::utf8(b"name"));
        vector::push_back(&mut keys, string::utf8(b"image_url"));
        

        let mut values = vector::empty();
        // {name} and {image_url} tell Sui to read those fields from your struct
        vector::push_back(&mut values, string::utf8(b"{name}")); 
        vector::push_back(&mut values, string::utf8(b"{image_url}"));
        

        let mut display = display::new_with_fields<Entertain>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

      
        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
        transfer::public_transfer(AdminCap { id: object::new(ctx) }, ctx.sender());

        // Share the registry so users can mint
        transfer::share_object(Registry {
            id: object::new(ctx),
            templates: vector::empty(),
            year:2026
        });

        transfer::share_object(DailySpecial {
            id: object::new(ctx),
            current: Template { 
                name: b"Excalibur".to_string(), 
                url: b"https://arweave.net/b20d095OIoutw3_9d48lu03Ce_JC3YaHcbQw0lxe8O8".to_string() 
            },
            
        });
    }



    

    entry fun remove_option(
        _: &AdminCap, 
        registry: &mut Registry, 
        index: u64
    ) {
        let len = vector::length(&registry.templates);
        // Ensure the index actually exists
        assert!(index < len, EInvalidIndex);

       
        vector::swap_remove(&mut registry.templates, index);
    }


    ///--mint-special
    entry fun mint_special(
        special: &DailySpecial, 
        ctx: &mut TxContext
    ) {
        let nft = Entertain {
            id: object::new(ctx),
            name: special.current.name,      
            image_url: special.current.url,  
        };
        event::emit(
            Minted{
                id:object::uid_to_inner(&nft.id),
                name:nft.name
            }
        );
        transfer::public_transfer(nft, ctx.sender());
    }

    entry fun update_special(
        _: &AdminCap, 
        special: &mut DailySpecial,
        registry: &mut Registry, // Optional: Only needed if you want to save the old one
        name: String, 
        url: String
    ) {
        // 1. Take the current special and save it to the big registry
        // (This makes the registry bigger, but we are the Admin, we pay the gas)
        let old_template = special.current;
        vector::push_back(&mut registry.templates, old_template);

        // 2. Update the special to the new one
        special.current = Template { name, url };
    }

    ///---///
    entry fun mint_random(
        registry: &Registry, 
        
        r: &Random, 
        ctx: &mut TxContext
    ) {
        let total_options = vector::length(&registry.templates);
        assert!(total_options > 0, InvalidRegistrty); 
        
        // 1. Generate Random Index
        let mut generator = random::new_generator(r, ctx);
        let random_index = generator.generate_u64_in_range(0, total_options-1);

        
        let template = vector::borrow(&registry.templates, random_index);

        // 3. Create the NFT by COPYING the data
        let nft = Entertain {
            id: object::new(ctx),
            name: template.name,      
            image_url: template.url,  
           
        };
        event::emit(
            Minted{
                id:object::uid_to_inner(&nft.id),
                name:nft.name
            }
        );
        transfer::public_transfer(nft, ctx.sender());
    }

    entry fun burn(nft: Entertain) {
        let Entertain { id, image_url: _, name: _, } = nft;
        object::delete(id);
    }

    entry fun create_new_registry(_cap: &AdminCap, year:u64,ctx: &mut TxContext) {
        let new_registry = Registry {
            id: object::new(ctx),
            templates: vector::empty(),
            year:year
        };
        
       
        transfer::share_object(new_registry);
    }